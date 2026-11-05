from django.conf import settings
from django.db import models


class FirebaseAccount(models.Model):
    """Liên kết tài khoản Firebase Auth (định danh đăng nhập) với User nội bộ (chủ sở hữu dữ liệu)."""

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='firebase_account')
    uid = models.CharField(max_length=128, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.uid} -> {self.user}'
