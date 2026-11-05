from unittest import mock

import requests
from django.test import SimpleTestCase
from rest_framework import status
from rest_framework.test import APIClient

from soa_common.registry_client import ServiceUnavailable

SERVICE_URLS = {
    'auth-service': 'http://auth.internal:8001',
    'receipt-service': 'http://receipt.internal:8002',
}


def fake_response(status_code=200, json_body=b'{}', content_type='application/json'):
    response = requests.Response()
    response.status_code = status_code
    response._content = json_body
    response.headers['Content-Type'] = content_type
    return response


@mock.patch('routing.client.discover', side_effect=SERVICE_URLS.__getitem__)
@mock.patch('routing.client.requests.request')
class GatewayTests(SimpleTestCase):
    def setUp(self):
        self.client = APIClient()

    def test_routes_auth_prefix_to_auth_service(self, request_mock, _discover):
        request_mock.return_value = fake_response(201, b'{"access": "a"}')

        response = self.client.post('/api/auth/register/', {'email': 'a@b.c'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.json(), {'access': 'a'})
        method, url = request_mock.call_args.args
        self.assertEqual((method, url), ('POST', 'http://auth.internal:8001/api/auth/register/'))
        self.assertEqual(request_mock.call_args.kwargs['data'], b'{"email":"a@b.c"}')

    def test_routes_receipts_with_token_query_and_forwarded_host(self, request_mock, _discover):
        request_mock.return_value = fake_response(200, b'[]')

        self.client.get('/api/receipts/?page=2', HTTP_AUTHORIZATION='Bearer token', HTTP_X_INTERNAL='secret')

        _method, url = request_mock.call_args.args
        headers = request_mock.call_args.kwargs['headers']
        self.assertEqual(url, 'http://receipt.internal:8002/api/receipts/?page=2')
        self.assertEqual(headers['Authorization'], 'Bearer token')
        self.assertEqual(headers['X-Forwarded-Host'], 'testserver')
        self.assertEqual(headers['X-Forwarded-For'], '127.0.0.1')
        self.assertNotIn('X-Internal', headers)

    def test_media_is_served_by_receipt_service(self, request_mock, _discover):
        request_mock.return_value = fake_response(200, b'jpeg-bytes', 'image/jpeg')

        response = self.client.get('/media/receipts/1/a.jpg')

        self.assertEqual(response.content, b'jpeg-bytes')
        self.assertEqual(response['Content-Type'], 'image/jpeg')

    def test_returns_503_when_service_not_registered(self, request_mock, discover_mock):
        discover_mock.side_effect = ServiceUnavailable('auth-service')

        response = self.client.post('/api/auth/login/', {}, format='json')

        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        self.assertIn('detail', response.json())
        request_mock.assert_not_called()

    def test_returns_503_when_service_does_not_answer(self, request_mock, _discover):
        request_mock.side_effect = requests.ConnectionError()

        response = self.client.get('/api/receipts/')

        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)

    def test_overview_composes_auth_and_receipt_services(self, request_mock, _discover):
        def answer(method, url, **kwargs):
            if url.endswith('/api/auth/me/'):
                return fake_response(200, b'{"id": 1, "email": "a@b.c"}')
            return fake_response(200, b'{"total": 5, "today": 2}')

        request_mock.side_effect = answer

        response = self.client.get('/api/overview/', HTTP_AUTHORIZATION='Bearer token')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            response.json(), {'user': {'id': 1, 'email': 'a@b.c'}, 'receipts': {'total': 5, 'today': 2}}
        )

    def test_overview_passes_through_auth_error(self, request_mock, _discover):
        request_mock.return_value = fake_response(401, b'{"detail": "Token is invalid"}')

        response = self.client.get('/api/overview/')

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertEqual(request_mock.call_count, 1)
