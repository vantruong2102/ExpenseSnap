from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from accounts.serializers import FirebaseLoginSerializer, UserSerializer
from soa_common.firebase import FirebaseNotConfigured


class FirebaseLoginView(generics.GenericAPIView):
    """Đổi Firebase ID token lấy JWT của hệ thống.

    Firebase Auth lo phần đăng nhập (email/mật khẩu, Google). auth-service là nơi duy nhất tin Firebase,
    các service khác chỉ cần kiểm tra JWT nội bộ nên không phụ thuộc vào Firebase (Loose Coupling).
    """

    serializer_class = FirebaseLoginSerializer
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except FirebaseNotConfigured:
            return Response(
                {'detail': 'auth-service chưa được cấu hình Firebase Admin (GOOGLE_APPLICATION_CREDENTIALS).'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                'user': UserSerializer(user).data,
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            },
            status=status.HTTP_200_OK,
        )


class MeView(generics.RetrieveAPIView):
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user
