from datetime import timedelta

from django.test import override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from registry.models import ServiceInstance

TOKEN = 'test-registry-token'
PAYLOAD = {
    'name': 'receipt-service',
    'version': '1.0.0',
    'base_url': 'http://127.0.0.1:8002',
    'health_url': 'http://127.0.0.1:8002/health/',
    'contract_url': 'http://127.0.0.1:8002/api/schema/',
}


@override_settings(SERVICE_REGISTRY_TOKEN=TOKEN, SERVICE_TTL_SECONDS=60)
class RegistryTests(APITestCase):
    list_url = reverse('service-list')

    def register(self, **overrides):
        return self.client.post(self.list_url, {**PAYLOAD, **overrides}, format='json', HTTP_X_SERVICE_TOKEN=TOKEN)

    def test_register_requires_service_token(self):
        response = self.client.post(self.list_url, PAYLOAD, format='json')

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertFalse(ServiceInstance.objects.exists())

    def test_register_then_discover(self):
        self.assertEqual(self.register().status_code, status.HTTP_201_CREATED)

        response = self.client.get(reverse('service-detail', args=['receipt-service']))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['base_url'], 'http://127.0.0.1:8002')
        self.assertEqual(response.data['status'], 'UP')

    def test_register_again_updates_instead_of_duplicating(self):
        self.register()
        response = self.register(base_url='http://10.0.0.5:8002')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(ServiceInstance.objects.count(), 1)
        self.assertEqual(ServiceInstance.objects.get().base_url, 'http://10.0.0.5:8002')

    def test_expired_service_is_not_discoverable(self):
        self.register()
        ServiceInstance.objects.update(last_heartbeat=timezone.now() - timedelta(seconds=120))

        response = self.client.get(reverse('service-detail', args=['receipt-service']))

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        listing = self.client.get(self.list_url)
        self.assertEqual(listing.data[0]['status'], 'DOWN')

    def test_deregister(self):
        self.register()
        response = self.client.delete(reverse('service-detail', args=['receipt-service']), HTTP_X_SERVICE_TOKEN=TOKEN)

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(ServiceInstance.objects.exists())
