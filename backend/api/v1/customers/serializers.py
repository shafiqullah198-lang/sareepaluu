from django.db.models import Sum
from rest_framework import serializers

from dashboard.models import Customer
from backend.api.v1.orders.serializers import OrderSerializer


class CustomerSerializer(serializers.ModelSerializer):
    total_orders = serializers.IntegerField(read_only=True)
    total_spent = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    total_paid = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = Customer
        fields = ('id', 'name', 'phone', 'total_orders', 'total_spent', 'total_paid')


class CustomerDetailSerializer(CustomerSerializer):
    purchase_history = serializers.SerializerMethodField()

    class Meta(CustomerSerializer.Meta):
        fields = CustomerSerializer.Meta.fields + ('purchase_history',)

    def get_purchase_history(self, obj):
        orders = obj.order_set.select_related('customer').prefetch_related('items__variant__product').order_by('-date')[:50]
        return OrderSerializer(orders, many=True, context=self.context).data

