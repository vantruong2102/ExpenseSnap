import uuid
from pathlib import Path

from django.conf import settings
from django.db import models


def receipt_upload_path(instance, filename):
    extension = Path(filename).suffix.lower() or '.jpg'
    return f'receipts/{instance.user_id}/{uuid.uuid4().hex}{extension}'


class Receipt(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='receipts')
    image = models.ImageField(upload_to=receipt_upload_path)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Receipt #{self.pk} - {self.user}'
