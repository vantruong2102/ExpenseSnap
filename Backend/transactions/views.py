from rest_framework import mixins, viewsets
from rest_framework.parsers import FormParser, MultiPartParser

from transactions.models import Receipt
from transactions.serializers import ReceiptSerializer


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
        return Receipt.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def perform_destroy(self, instance):
        instance.image.delete(save=False)
        instance.delete()
