from rest_framework import serializers

from receipts.models import Receipt

MAX_RECEIPT_SIZE_MB = 10


class ReceiptSerializer(serializers.ModelSerializer):
    class Meta:
        model = Receipt
        fields = ['id', 'image', 'created_at']
        read_only_fields = ['id', 'created_at']

    def validate_image(self, value):
        if value.size > MAX_RECEIPT_SIZE_MB * 1024 * 1024:
            raise serializers.ValidationError(f'Ảnh hóa đơn không được vượt quá {MAX_RECEIPT_SIZE_MB}MB.')
        return value


class ReceiptStatsSerializer(serializers.Serializer):
    total = serializers.IntegerField()
    today = serializers.IntegerField()
