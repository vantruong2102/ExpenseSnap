from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()

VALID_PAYLOAD = {
    'full_name': 'Nguyễn Văn Trí',
    'email': 'Tri@Example.com',
    'password': 'ExpenseSnap@2026',
    'password_confirm': 'ExpenseSnap@2026',
}


class RegisterTests(APITestCase):
    url = reverse('auth-register')

    def test_register_creates_user_and_returns_tokens(self):
        response = self.client.post(self.url, VALID_PAYLOAD, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertEqual(response.data['user']['email'], 'tri@example.com')
        self.assertEqual(response.data['user']['full_name'], 'Nguyễn Văn Trí')
        user = User.objects.get(username='tri@example.com')
        self.assertTrue(user.check_password(VALID_PAYLOAD['password']))

    def test_register_rejects_duplicate_email_case_insensitive(self):
        self.client.post(self.url, VALID_PAYLOAD, format='json')
        response = self.client.post(self.url, {**VALID_PAYLOAD, 'email': 'TRI@example.com'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('email', response.data)
        self.assertEqual(User.objects.count(), 1)

    def test_register_rejects_mismatched_password(self):
        response = self.client.post(self.url, {**VALID_PAYLOAD, 'password_confirm': 'Other@2026'}, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('password_confirm', response.data)

    def test_register_rejects_weak_password(self):
        response = self.client.post(
            self.url, {**VALID_PAYLOAD, 'password': '123', 'password_confirm': '123'}, format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('password', response.data)

    def test_register_rejects_invalid_email_and_blank_name(self):
        response = self.client.post(
            self.url, {**VALID_PAYLOAD, 'email': 'not-an-email', 'full_name': '   '}, format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('email', response.data)
        self.assertIn('full_name', response.data)


class LoginTests(APITestCase):
    def setUp(self):
        self.client.post(reverse('auth-register'), VALID_PAYLOAD, format='json')

    def test_login_with_email_returns_tokens(self):
        response = self.client.post(
            reverse('auth-login'),
            {'email': 'TRI@example.com', 'password': VALID_PAYLOAD['password']},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)

    def test_login_with_wrong_password_fails(self):
        response = self.client.post(
            reverse('auth-login'), {'email': 'tri@example.com', 'password': 'wrong'}, format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_me_requires_token(self):
        self.assertEqual(self.client.get(reverse('auth-me')).status_code, status.HTTP_401_UNAUTHORIZED)

        login = self.client.post(
            reverse('auth-login'), {'email': 'tri@example.com', 'password': VALID_PAYLOAD['password']}, format='json'
        )
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {login.data["access"]}')
        response = self.client.get(reverse('auth-me'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['email'], 'tri@example.com')
