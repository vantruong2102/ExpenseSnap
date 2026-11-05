from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from accounts.views import (
    LoginView,
    MeView,
    RegisterView,
    PasswordResetRequestView,
    PasswordResetVerifyView,
    PasswordResetCompleteView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='auth-register'),
    path('login/', LoginView.as_view(), name='auth-login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='auth-token-refresh'),
    path('me/', MeView.as_view(), name='auth-me'),
    path('password-reset/request/', PasswordResetRequestView.as_view(), name='password-reset-request'),
    path('password-reset/verify/', PasswordResetVerifyView.as_view(), name='password-reset-verify'),
    path('password-reset/complete/', PasswordResetCompleteView.as_view(), name='password-reset-complete'),
]
