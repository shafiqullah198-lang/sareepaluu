from rest_framework import serializers


class CartItemSerializer(serializers.Serializer):
    variant_id = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1)
    price = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    needs_stitching = serializers.BooleanField(required=False, default=False)
    stitching_price = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, default=0)
    delivery_date = serializers.DateField(required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_blank=True)


class CheckoutSerializer(serializers.Serializer):
    cart = CartItemSerializer(many=True)
    customer = serializers.DictField(required=False)
    discount = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, default=0)
    manual_total = serializers.DecimalField(max_digits=12, decimal_places=2, required=False, allow_null=True)
    amount_paid = serializers.DecimalField(max_digits=12, decimal_places=2, required=False, allow_null=True)

