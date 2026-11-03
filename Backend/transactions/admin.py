from django.contrib import admin

from transactions.models import Receipt


@admin.register(Receipt)
class ReceiptAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'image', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__email']
