from rest_framework import serializers

from dashboard.models import Darzi, Order, OrderItem, OrderPayment
from backend.api.v1.products.serializers import ProductVariantSerializer


class DarziSerializer(serializers.ModelSerializer):
    class Meta:
        model = Darzi
        fields = ('id', 'name', 'phone')


class OrderItemSerializer(serializers.ModelSerializer):
    variant_detail = ProductVariantSerializer(source='variant', read_only=True)
    total_price = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    darzi_detail = DarziSerializer(source='darzi', read_only=True)
    token_number = serializers.CharField(source='order.token_number', read_only=True)
    customer_name = serializers.CharField(source='order.customer.name', read_only=True)

    class Meta:
        model = OrderItem
        fields = (
            'id', 'order', 'token_number', 'customer_name', 'variant', 'variant_detail', 'quantity', 'price',
            'cost_price', 'needs_stitching', 'stitching_price',
            'stitching_status', 'delivery_date', 'notes', 'total_price', 'darzi', 'darzi_detail',
        )
        read_only_fields = ('order', 'cost_price')


class OrderPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderPayment
        fields = ('id', 'order', 'amount', 'date', 'note')
        read_only_fields = ('order', 'date')


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    payments = OrderPaymentSerializer(many=True, read_only=True)
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone', read_only=True)
    balance_due = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    product_names = serializers.CharField(read_only=True)
    invoice_url = serializers.SerializerMethodField()

    def get_invoice_url(self, obj):
        request = self.context.get('request')
        if request:
            from django.urls import reverse
            path = reverse('invoice', args=[obj.id])
            return request.build_absolute_uri(path)
        return f"/invoice/{obj.id}/"

    class Meta:
        model = Order
        fields = (
            'id', 'token_number', 'customer', 'customer_name', 'customer_phone',
            'date', 'total_amount', 'discount', 'final_amount', 'amount_paid',
            'payment_status', 'balance_due', 'product_names', 'items', 'payments',
            'invoice_url',
        )
        read_only_fields = ('token_number', 'date', 'total_amount', 'final_amount', 'amount_paid', 'payment_status')


class PaymentCreateSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    note = serializers.CharField(required=False, allow_blank=True, max_length=100)

