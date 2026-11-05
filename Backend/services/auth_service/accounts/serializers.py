import logging

from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import transaction
from firebase_admin import auth as firebase_auth
from rest_framework import serializers

from accounts.models import FirebaseAccount
from soa_common.firebase import get_firebase_app

User = get_user_model()
logger = logging.getLogger(__name__)


class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='first_name')

    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'date_joined']


class FirebaseLoginSerializer(serializers.Serializer):
    id_token = serializers.CharField(write_only=True)
    # Chỉ gửi khi vừa đăng ký, để lưu họ tên người dùng nhập trên form
    full_name = serializers.CharField(max_length=150, required=False, allow_blank=True, write_only=True)

    def validate_id_token(self, value):
        get_firebase_app()
        try:
            claims = firebase_auth.verify_id_token(value)
        except (ValueError, firebase_auth.InvalidIdTokenError, firebase_auth.CertificateFetchError) as error:
            logger.warning('Firebase ID token rejected: %s: %s', type(error).__name__, error)
            message = 'Phiên đăng nhập Firebase không hợp lệ hoặc đã hết hạn.'
            if settings.DEBUG:
                message = f'{message} ({type(error).__name__}: {error})'
            raise serializers.ValidationError(message) from error
        if not claims.get('email'):
            raise serializers.ValidationError('Tài khoản Firebase chưa có email.')
        return claims

    def save(self):
        claims = self.validated_data['id_token']
        uid = claims['uid']
        email = claims['email'].strip().lower()
        full_name = (self.validated_data.get('full_name') or claims.get('name') or '').strip()[:150]

        with transaction.atomic():
            account = FirebaseAccount.objects.select_related('user').filter(uid=uid).first()
            if account:
                user = account.user
            else:
                # Firebase bảo đảm mỗi email chỉ có một tài khoản, nên liên kết theo email là an toàn
                user = User.objects.filter(username=email).first()
                if user is None:
                    user = User(username=email, email=email, first_name=full_name)
                    # Mật khẩu chỉ nằm ở Firebase, không lưu bản thứ hai trong database
                    user.set_unusable_password()
                    user.save()
                FirebaseAccount.objects.create(user=user, uid=uid)

            if full_name and not user.first_name:
                user.first_name = full_name
                user.save(update_fields=['first_name'])
        return user
