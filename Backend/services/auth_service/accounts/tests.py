import re
from unittest import mock

from django.contrib.auth import get_user_model
from django.core import mail
from django.core.cache import cache
from django.test import override_settings
from django.urls import reverse
from firebase_admin import auth as firebase_auth
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import FirebaseAccount

User = get_user_model()

CLAIMS = {'uid': 'firebase-uid-1', 'email': 'Tri@Example.com', 'name': 'Google Name'}


@mock.patch('accounts.serializers.get_firebase_app')
@mock.patch('accounts.serializers.firebase_auth.verify_id_token', return_value=CLAIMS)
class FirebaseLoginTests(APITestCase):
    url = reverse('auth-firebase')

    def test_first_login_creates_user_without_local_password(self, verify_mock, _app):
        response = self.client.post(self.url, {'id_token': 'token', 'full_name': 'Nguyễn Văn Trí'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertEqual(response.data['user']['email'], 'tri@example.com')
        self.assertEqual(response.data['user']['full_name'], 'Nguyễn Văn Trí')
        user = User.objects.get(username='tri@example.com')
        self.assertFalse(user.has_usable_password())
        self.assertEqual(user.firebase_account.uid, 'firebase-uid-1')
        verify_mock.assert_called_once_with('token')

    def test_second_login_reuses_same_user(self, _verify, _app):
        first = self.client.post(self.url, {'id_token': 'token'}, format='json')
        second = self.client.post(self.url, {'id_token': 'token'}, format='json')

        self.assertEqual(first.data['user']['id'], second.data['user']['id'])
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(FirebaseAccount.objects.count(), 1)

    def test_name_falls_back_to_firebase_profile(self, _verify, _app):
        response = self.client.post(self.url, {'id_token': 'token'}, format='json')

        self.assertEqual(response.data['user']['full_name'], 'Google Name')

    def test_links_existing_user_with_same_email(self, _verify, _app):
        existing = User.objects.create_user(username='tri@example.com', email='tri@example.com')

        response = self.client.post(self.url, {'id_token': 'token'}, format='json')

        self.assertEqual(response.data['user']['id'], existing.id)
        self.assertEqual(FirebaseAccount.objects.get().user, existing)

    def test_rejects_invalid_firebase_token(self, verify_mock, _app):
        verify_mock.side_effect = firebase_auth.InvalidIdTokenError('bad token')

        response = self.client.post(self.url, {'id_token': 'bad'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('id_token', response.data)
        self.assertFalse(User.objects.exists())

    def test_returned_access_token_works_for_me(self, _verify, _app):
        login = self.client.post(self.url, {'id_token': 'token'}, format='json')
        self.assertEqual(self.client.get(reverse('auth-me')).status_code, status.HTTP_401_UNAUTHORIZED)

        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {login.data["access"]}')
        response = self.client.get(reverse('auth-me'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['email'], 'tri@example.com')


class FirebaseNotConfiguredTests(APITestCase):
    def test_returns_503_when_service_account_missing(self):
        from soa_common.firebase import FirebaseNotConfigured

        with mock.patch('accounts.serializers.get_firebase_app', side_effect=FirebaseNotConfigured('missing')):
            response = self.client.post(reverse('auth-firebase'), {'id_token': 'token'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        self.assertIn('detail', response.data)


@override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend', DEFAULT_FROM_EMAIL='no-reply@x.com')
@mock.patch('accounts.password_reset.get_firebase_app')
class PasswordResetTests(APITestCase):
    email = 'tri@example.com'

    def setUp(self):
        cache.clear()

    def request_code(self):
        with mock.patch('accounts.password_reset.firebase_auth.get_user_by_email'):
            response = self.client.post(reverse('password-reset-request'), {'email': self.email}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        return re.search(r'\b(\d{6})\b', mail.outbox[-1].body).group(1)

    def test_full_reset_flow_updates_firebase_password(self, _app):
        otp = self.request_code()

        verify = self.client.post(reverse('password-reset-verify'), {'email': self.email, 'otp': otp}, format='json')
        self.assertEqual(verify.status_code, status.HTTP_200_OK)

        user = mock.Mock(uid='firebase-uid-1')
        with mock.patch('accounts.password_reset.firebase_auth.get_user_by_email', return_value=user), \
                mock.patch('accounts.password_reset.firebase_auth.update_user') as update_mock, \
                mock.patch('accounts.password_reset.firebase_auth.revoke_refresh_tokens'):
            complete = self.client.post(
                reverse('password-reset-complete'),
                {'reset_token': verify.data['reset_token'], 'password': 'NewPass@2026'},
                format='json',
            )

        self.assertEqual(complete.status_code, status.HTTP_200_OK)
        update_mock.assert_called_once_with('firebase-uid-1', password='NewPass@2026')

    def test_unknown_email_gets_same_answer_without_sending_mail(self, _app):
        with mock.patch(
            'accounts.password_reset.firebase_auth.get_user_by_email',
            side_effect=firebase_auth.UserNotFoundError('not found'),
        ):
            response = self.client.post(reverse('password-reset-request'), {'email': 'nobody@x.com'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(mail.outbox), 0)

    def test_wrong_otp_is_rejected(self, _app):
        otp = self.request_code()
        wrong = '000000' if otp != '000000' else '111111'

        response = self.client.post(reverse('password-reset-verify'), {'email': self.email, 'otp': wrong}, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('otp', response.data)

    def test_throttle_uses_client_ip_forwarded_by_gateway(self, _app):
        url = reverse('password-reset-request')
        with mock.patch(
            'accounts.password_reset.firebase_auth.get_user_by_email',
            side_effect=firebase_auth.UserNotFoundError('not found'),
        ):
            for _ in range(3):
                self.client.post(url, {'email': self.email}, format='json', HTTP_X_FORWARDED_FOR='1.1.1.1')
            blocked = self.client.post(url, {'email': self.email}, format='json', HTTP_X_FORWARDED_FOR='1.1.1.1')
            other_user = self.client.post(url, {'email': self.email}, format='json', HTTP_X_FORWARDED_FOR='2.2.2.2')

        self.assertEqual(blocked.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertEqual(other_user.status_code, status.HTTP_200_OK)
