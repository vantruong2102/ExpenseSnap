from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from registry.models import ServiceInstance
from registry.permissions import IsRegisteredServiceOrReadOnly
from registry.serializers import ServiceInstanceSerializer


class ServiceListView(APIView):
    permission_classes = [IsRegisteredServiceOrReadOnly]
    serializer_class = ServiceInstanceSerializer

    def get(self, request):
        services = ServiceInstance.objects.all()
        return Response(ServiceInstanceSerializer(services, many=True).data)

    def post(self, request):
        """Đăng ký mới hoặc gia hạn heartbeat (upsert theo tên service)."""
        serializer = ServiceInstanceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        instance, created = ServiceInstance.objects.update_or_create(
            name=data['name'],
            defaults={**data, 'last_heartbeat': timezone.now()},
        )
        return Response(
            ServiceInstanceSerializer(instance).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class ServiceDetailView(APIView):
    permission_classes = [IsRegisteredServiceOrReadOnly]
    serializer_class = ServiceInstanceSerializer

    def get(self, request, name):
        """Chỉ trả về service còn sống, để bên gọi không bị chuyển tới service đã tắt."""
        instance = get_object_or_404(ServiceInstance.objects.alive(), name=name)
        return Response(ServiceInstanceSerializer(instance).data)

    def delete(self, request, name):
        get_object_or_404(ServiceInstance, name=name).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
