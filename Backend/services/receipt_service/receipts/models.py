import uuid
from pathlib import Path

from django.db import models


def receipt_upload_path(instance, filename):
    extension = Path(filename).suffix.lower() or '.jpg'
    return f'receipts/{instance.user_id}/{uuid.uuid4().hex}{extension}'


class Receipt(models.Model):
    # Chỉ lưu id người dùng lấy từ JWT, không khóa ngoại sang database của auth-service (Loose Coupling)
    user_id = models.PositiveBigIntegerField(db_index=True)
    image = models.ImageField(upload_to=receipt_upload_path)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Receipt #{self.pk} - user {self.user_id}'
