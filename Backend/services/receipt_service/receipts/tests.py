import io
import shutil
import tempfile

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.urls import reverse
from PIL import Image
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import AccessToken

from receipts.models import Receipt

TEMP_MEDIA_ROOT = tempfile.mkdtemp()
USER_ID = 1
OTHER_USER_ID = 2


def make_image_file(name='receipt.jpg'):
    buffer = io.BytesIO()
    Image.new('RGB', (20, 20), color='white').save(buffer, format='JPEG')
    return SimpleUploadedFile(name, buffer.getvalue(), content_type='image/jpeg')


def make_access_token(user_id):
    """Token giống hệt token do auth-service phát hành (cùng khóa ký), không cần gọi auth-service."""
    token = AccessToken()
    token['user_id'] = user_id
    return str(token)


@override_settings(MEDIA_ROOT=TEMP_MEDIA_ROOT)
class ReceiptApiTests(APITestCase):
    list_url = reverse('receipt-list')

    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        shutil.rmtree(TEMP_MEDIA_ROOT, ignore_errors=True)

    def authenticate(self, user_id=USER_ID):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {make_access_token(user_id)}')

    def test_upload_requires_authentication(self):
        response = self.client.post(self.list_url, {'image': make_image_file()}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_rejects_token_with_invalid_signature(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {make_access_token(USER_ID)}tampered')

        self.assertEqual(self.client.get(self.list_url).status_code, status.HTTP_401_UNAUTHORIZED)

    def test_upload_receipt_image(self):
        self.authenticate()
        response = self.client.post(self.list_url, {'image': make_image_file()}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        receipt = Receipt.objects.get(pk=response.data['id'])
        self.assertEqual(receipt.user_id, USER_ID)
        self.assertTrue(receipt.image.name.startswith(f'receipts/{USER_ID}/'))
        self.assertTrue(response.data['image'].startswith('http'))

    def test_image_url_uses_gateway_host(self):
        self.authenticate()
        response = self.client.post(
            self.list_url, {'image': make_image_file()}, format='multipart', HTTP_X_FORWARDED_HOST='localhost:8000'
        )

        self.assertTrue(response.data['image'].startswith('http://localhost:8000/media/'))

    def test_upload_rejects_non_image_file(self):
        self.authenticate()
        fake = SimpleUploadedFile('receipt.jpg', b'not an image', content_type='image/jpeg')
        response = self.client.post(self.list_url, {'image': fake}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('image', response.data)

    def test_upload_rejects_missing_image(self):
        self.authenticate()
        response = self.client.post(self.list_url, {}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_list_only_returns_own_receipts(self):
        Receipt.objects.create(user_id=USER_ID, image=make_image_file())
        Receipt.objects.create(user_id=OTHER_USER_ID, image=make_image_file())
        self.authenticate()

        response = self.client.get(self.list_url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_cannot_delete_other_users_receipt(self):
        receipt = Receipt.objects.create(user_id=OTHER_USER_ID, image=make_image_file())
        self.authenticate()

        response = self.client.delete(reverse('receipt-detail', args=[receipt.pk]))

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(Receipt.objects.filter(pk=receipt.pk).exists())

    def test_stats_counts_own_receipts(self):
        Receipt.objects.create(user_id=USER_ID, image=make_image_file())
        Receipt.objects.create(user_id=USER_ID, image=make_image_file())
        Receipt.objects.create(user_id=OTHER_USER_ID, image=make_image_file())
        self.authenticate()

        response = self.client.get(reverse('receipt-stats'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, {'total': 2, 'today': 2})
