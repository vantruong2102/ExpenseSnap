import requests
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from routing.client import call_service
from soa_common.registry_client import ServiceUnavailable, list_services

# Header chỉ có ý nghĩa với một kết nối, không được chuyển tiếp nguyên trạng (RFC 9110)
HOP_BY_HOP_HEADERS = {
    'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailer',
    'transfer-encoding', 'upgrade', 'content-encoding', 'content-length',
}


def unavailable_response(service_name):
    return JsonResponse(
        {'detail': f'Dịch vụ {service_name} tạm thời không khả dụng. Vui lòng thử lại sau.'},
        status=status.HTTP_503_SERVICE_UNAVAILABLE,
        json_dumps_params={'ensure_ascii': False},
    )


def to_django_response(upstream):
    response = HttpResponse(upstream.content, status=upstream.status_code)
    for name, value in upstream.headers.items():
        if name.lower() not in HOP_BY_HOP_HEADERS:
            response[name] = value
    return response


@csrf_exempt
def proxy(request, service_name):
    """Chuyển tiếp nguyên request tới service sở hữu tiền tố URL (xem GATEWAY_ROUTES)."""
    try:
        upstream = call_service(service_name, request.method, request.get_full_path(), request, request.body)
    except (ServiceUnavailable, requests.RequestException):
        return unavailable_response(service_name)
    return to_django_response(upstream)


class OverviewView(APIView):
    """API tổng hợp (Composability): ghép thông tin người dùng từ auth-service và thống kê từ receipt-service."""

    @extend_schema(
        responses=inline_serializer(
            'Overview',
            {
                'user': inline_serializer('OverviewUser', {
                    'id': serializers.IntegerField(),
                    'email': serializers.EmailField(),
                    'full_name': serializers.CharField(),
                    'date_joined': serializers.DateTimeField(),
                }),
                'receipts': inline_serializer('OverviewReceipts', {
                    'total': serializers.IntegerField(),
                    'today': serializers.IntegerField(),
                }),
            },
        )
    )
    def get(self, request):
        results = {}
        for key, service_name, path in [
            ('user', 'auth-service', '/api/auth/me/'),
            ('receipts', 'receipt-service', '/api/receipts/stats/'),
        ]:
            try:
                upstream = call_service(service_name, 'GET', path, request)
            except (ServiceUnavailable, requests.RequestException):
                return unavailable_response(service_name)
            if upstream.status_code != status.HTTP_200_OK:
                # Ví dụ token hết hạn: trả nguyên lỗi của service cho client
                return to_django_response(upstream)
            results[key] = upstream.json()
        return Response(results)


class ServiceCatalogView(APIView):
    """Danh mục service đang hoạt động cùng link hợp đồng OpenAPI của từng service."""

    @extend_schema(responses=inline_serializer('ServiceCatalog', {
        'name': serializers.CharField(),
        'version': serializers.CharField(),
        'description': serializers.CharField(),
        'status': serializers.CharField(),
        'contract_url': serializers.URLField(),
    }, many=True))
    def get(self, request):
        try:
            services = list_services()
        except requests.RequestException:
            return unavailable_response('registry-service')
        fields = ['name', 'version', 'description', 'status', 'contract_url']
        return Response([{field: service[field] for field in fields} for service in services])
