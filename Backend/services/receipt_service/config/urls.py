from django.conf import settings
from django.conf.urls.static import static
from django.urls import include, path

from soa_common.views import common_urlpatterns

urlpatterns = [
    path('api/', include('receipts.urls')),
    *common_urlpatterns,
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
