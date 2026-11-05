"""Quên mật khẩu: gửi OTP qua email, xác minh OTP, rồi đặt mật khẩu mới trên Firebase Auth."""

import hashlib
import secrets
from email.utils import formataddr

import firebase_admin
from django.conf import settings
from django.core import signing
from django.core.cache import cache
from django.core.mail import send_mail
from django.utils.crypto import salted_hmac
from firebase_admin import auth as firebase_auth
from rest_framework import generics, permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle

from soa_common.firebase import get_firebase_app

OTP_TTL_SECONDS = 300
RESET_TOKEN_TTL_SECONDS = 300
RESET_SALT = 'accounts.firebase-password-reset'


def _email_key(email):
    return hashlib.sha256(email.strip().lower().encode()).hexdigest()


class PasswordResetRequestThrottle(AnonRateThrottle):
    scope = 'password_reset_request'
    rate = '5/minute'


class PasswordResetVerifyThrottle(AnonRateThrottle):
    scope = 'password_reset_verify'
    rate = '20/minute'


class PasswordResetCompleteThrottle(AnonRateThrottle):
    scope = 'password_reset_complete'
    rate = '10/minute'


class PasswordResetRequestView(generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [PasswordResetRequestThrottle]

    def post(self, request):
        email = str(request.data.get('email', '')).strip().lower()
        if not email or '@' not in email:
            raise ValidationError({'email': 'Vui lòng nhập email hợp lệ.'})

        # Keep the response identical for known and unknown Firebase accounts.
        response_message = 'Nếu email có tài khoản ExpenseSnap, mã xác minh sẽ được gửi đến hộp thư.'
        key = _email_key(email)
        try:
            get_firebase_app()
            firebase_auth.get_user_by_email(email)
        except firebase_auth.UserNotFoundError:
            return Response({'message': response_message}, status=status.HTTP_200_OK)
        except Exception:
            return Response(
                {'message': 'Dịch vụ đặt lại mật khẩu chưa được cấu hình Firebase Admin.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        otp = f'{secrets.randbelow(1_000_000):06d}'
        digest = salted_hmac('expense-snap-password-reset', f'{key}:{otp}').hexdigest()
        try:
            send_mail(
                'Mã đặt lại mật khẩu ExpenseSnap',
                f'Mã xác minh của bạn là {otp}. Mã có hiệu lực trong 5 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.',
                formataddr((settings.EMAIL_DISPLAY_NAME, settings.DEFAULT_FROM_EMAIL)),
                [email],
                fail_silently=False,
            )
        except Exception:
            return Response(
                {'message': 'Không gửi được email. Kiểm tra cấu hình Gmail SMTP ở Backend/.env.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        cache.set(f'password-reset-otp:{key}', digest, timeout=OTP_TTL_SECONDS)
        cache.set(f'password-reset-attempts:{key}', 0, timeout=OTP_TTL_SECONDS)
        return Response({'message': response_message}, status=status.HTTP_200_OK)


class PasswordResetVerifyView(generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [PasswordResetVerifyThrottle]

    def post(self, request):
        email = str(request.data.get('email', '')).strip().lower()
        otp = str(request.data.get('otp', '')).strip()
        key = _email_key(email)
        cache_key = f'password-reset-otp:{key}'
        expected = cache.get(cache_key)
        attempts_key = f'password-reset-attempts:{key}'
        attempts = cache.get(attempts_key, 0)
        if not expected or attempts >= 5 or len(otp) != 6 or not otp.isdigit():
            raise ValidationError({'otp': 'Mã không đúng hoặc đã hết hạn. Hãy yêu cầu mã mới.'})

        actual = salted_hmac('expense-snap-password-reset', f'{key}:{otp}').hexdigest()
        if not secrets.compare_digest(expected, actual):
            cache.set(attempts_key, attempts + 1, timeout=OTP_TTL_SECONDS)
            raise ValidationError({'otp': 'Mã xác minh không chính xác.'})

        cache.delete(cache_key)
        nonce = secrets.token_urlsafe(24)
        cache.set(f'password-reset-token:{hashlib.sha256(nonce.encode()).hexdigest()}', email, timeout=RESET_TOKEN_TTL_SECONDS)
        token = signing.dumps({'email': email, 'nonce': nonce}, salt=RESET_SALT)
        return Response({'reset_token': token}, status=status.HTTP_200_OK)


class PasswordResetCompleteView(generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [PasswordResetCompleteThrottle]

    def post(self, request):
        token = str(request.data.get('reset_token', ''))
        password = str(request.data.get('password', ''))
        try:
            payload = signing.loads(token, salt=RESET_SALT, max_age=RESET_TOKEN_TTL_SECONDS)
        except signing.BadSignature:
            raise ValidationError({'reset_token': 'Phiên xác minh không hợp lệ hoặc đã hết hạn.'})

        email, nonce = payload.get('email', ''), payload.get('nonce', '')
        nonce_hash = hashlib.sha256(nonce.encode()).hexdigest()
        cache_key = f'password-reset-token:{nonce_hash}'
        if not email or not cache.get(cache_key):
            raise ValidationError({'reset_token': 'Mã xác minh đã được sử dụng hoặc đã hết hạn.'})
        if len(password) < 8 or password.isdigit():
            raise ValidationError({'password': 'Mật khẩu cần có ít nhất 8 ký tự và không được chỉ gồm số.'})

        try:
            get_firebase_app()
            user = firebase_auth.get_user_by_email(email)
            firebase_auth.update_user(user.uid, password=password)
            firebase_auth.revoke_refresh_tokens(user.uid)
        except firebase_admin.exceptions.FirebaseError:
            raise ValidationError({'email': 'Không thể cập nhật tài khoản Firebase.'})
        except Exception:
            return Response(
                {'message': 'Dịch vụ đặt lại mật khẩu chưa được cấu hình Firebase Admin.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        cache.delete(cache_key)
        return Response({'message': 'Đã đổi mật khẩu. Bạn có thể đăng nhập lại.'}, status=status.HTTP_200_OK)
