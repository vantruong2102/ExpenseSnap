from django.conf import settings
from django.http import JsonResponse
from django.urls import path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView


def health(request):
    return JsonResponse({'service': settings.SERVICE_NAME, 'status': 'UP'})


# Mỗi service include các URL này để có /health/, hợp đồng OpenAPI và trang tài liệu Swagger
common_urlpatterns = [
    path('health/', health, name='health'),
    path('api/schema/', SpectacularAPIView.as_view(permission_classes=[]), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema', permission_classes=[]), name='docs'),
]
