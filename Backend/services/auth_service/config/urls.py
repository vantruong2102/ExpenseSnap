from django.urls import include, path

from soa_common.views import common_urlpatterns

urlpatterns = [
    path('api/auth/', include('accounts.urls')),
    *common_urlpatterns,
]
