from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from accounts.password_reset import PasswordResetCompleteView, PasswordResetRequestView, PasswordResetVerifyView
from accounts.views import FirebaseLoginView, MeView

urlpatterns = [
    path('firebase/', FirebaseLoginView.as_view(), name='auth-firebase'),
    path('token/refresh/', TokenRefreshView.as_view(), name='auth-token-refresh'),
    path('me/', MeView.as_view(), name='auth-me'),
    path('password-reset/request/', PasswordResetRequestView.as_view(), name='password-reset-request'),
    path('password-reset/verify/', PasswordResetVerifyView.as_view(), name='password-reset-verify'),
    path('password-reset/complete/', PasswordResetCompleteView.as_view(), name='password-reset-complete'),
]
