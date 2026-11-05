from django.urls import path

from registry.views import ServiceDetailView, ServiceListView

urlpatterns = [
    path('services/', ServiceListView.as_view(), name='service-list'),
    path('services/<slug:name>/', ServiceDetailView.as_view(), name='service-detail'),
]
