from rest_framework import serializers

from registry.models import ServiceInstance


class ServiceInstanceSerializer(serializers.ModelSerializer):
    status = serializers.SerializerMethodField()

    class Meta:
        model = ServiceInstance
        fields = [
            'name', 'version', 'base_url', 'health_url', 'contract_url', 'description',
            'registered_at', 'last_heartbeat', 'status',
        ]
        read_only_fields = ['registered_at', 'last_heartbeat', 'status']
        # Cho phép POST lại cùng tên để gia hạn heartbeat
        extra_kwargs = {'name': {'validators': []}}

    def get_status(self, instance) -> str:
        return 'UP' if instance.is_alive else 'DOWN'
