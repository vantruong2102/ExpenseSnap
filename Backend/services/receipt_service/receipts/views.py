from django.utils import timezone
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from receipts.models import Receipt
from receipts.serializers import ReceiptSerializer, ReceiptStatsSerializer


class ReceiptViewSet(
    mixins.CreateModelMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    serializer_class = ReceiptSerializer
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        return Receipt.objects.filter(user_id=self.request.user.id)

    def perform_create(self, serializer):
        serializer.save(user_id=self.request.user.id)

    def perform_destroy(self, instance):
        instance.image.delete(save=False)
        instance.delete()

    @action(detail=False, methods=['get'], serializer_class=ReceiptStatsSerializer)
    def stats(self, request):
        receipts = self.get_queryset()
        data = {
            'total': receipts.count(),
            'today': receipts.filter(created_at__date=timezone.localdate()).count(),
        }
        return Response(ReceiptStatsSerializer(data).data)
