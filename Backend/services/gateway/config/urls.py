import re

from django.conf import settings
from django.urls import path, re_path

from routing.views import OverviewView, ServiceCatalogView, proxy
from soa_common.views import common_urlpatterns

urlpatterns = [
    path('api/overview/', OverviewView.as_view(), name='overview'),
    path('api/services/', ServiceCatalogView.as_view(), name='service-catalog'),
    *common_urlpatterns,
    *[
        re_path(rf'^{re.escape(prefix)}', proxy, {'service_name': service_name})
        for prefix, service_name in settings.GATEWAY_ROUTES
    ],
]
