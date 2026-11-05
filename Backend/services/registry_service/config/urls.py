from django.urls import include, path

from soa_common.views import common_urlpatterns

urlpatterns = [
    path('registry/', include('registry.urls')),
    *common_urlpatterns,
]
