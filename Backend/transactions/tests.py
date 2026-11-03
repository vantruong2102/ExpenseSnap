import io
import shutil
import tempfile

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.urls import reverse
from PIL import Image
from rest_framework import status
from rest_framework.test import APITestCase

from transactions.models import Receipt

User = get_user_model()
TEMP_MEDIA_ROOT = tempfile.mkdtemp()


def make_image_file(name='receipt.jpg'):
    buffer = io.BytesIO()
    Image.new('RGB', (20, 20), color='white').save(buffer, format='JPEG')
    return SimpleUploadedFile(name, buffer.getvalue(), content_type='image/jpeg')


@override_settings(MEDIA_ROOT=TEMP_MEDIA_ROOT)
class ReceiptApiTests(APITestCase):
    list_url = reverse('receipt-list')

    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        shutil.rmtree(TEMP_MEDIA_ROOT, ignore_errors=True)

    def setUp(self):
        self.user = User.objects.create_user(username='a@example.com', email='a@example.com', password='x')
        self.other_user = User.objects.create_user(username='b@example.com', email='b@example.com', password='x')

    def test_upload_requires_authentication(self):
        response = self.client.post(self.list_url, {'image': make_image_file()}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_upload_receipt_image(self):
        self.client.force_authenticate(self.user)
        response = self.client.post(self.list_url, {'image': make_image_file()}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        receipt = Receipt.objects.get(pk=response.data['id'])
        self.assertEqual(receipt.user, self.user)
        self.assertTrue(receipt.image.name.startswith(f'receipts/{self.user.pk}/'))
        self.assertTrue(response.data['image'].startswith('http'))

    def test_upload_rejects_non_image_file(self):
        self.client.force_authenticate(self.user)
        fake = SimpleUploadedFile('receipt.jpg', b'not an image', content_type='image/jpeg')
        response = self.client.post(self.list_url, {'image': fake}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('image', response.data)

    def test_upload_rejects_missing_image(self):
        self.client.force_authenticate(self.user)
        response = self.client.post(self.list_url, {}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_list_only_returns_own_receipts(self):
        Receipt.objects.create(user=self.user, image=make_image_file())
        Receipt.objects.create(user=self.other_user, image=make_image_file())
        self.client.force_authenticate(self.user)

        response = self.client.get(self.list_url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_cannot_delete_other_users_receipt(self):
        receipt = Receipt.objects.create(user=self.other_user, image=make_image_file())
        self.client.force_authenticate(self.user)

        response = self.client.delete(reverse('receipt-detail', args=[receipt.pk]))

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(Receipt.objects.filter(pk=receipt.pk).exists())
