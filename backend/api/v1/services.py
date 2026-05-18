from decimal import Decimal

from django.db import transaction
from django.utils import timezone
from rest_framework import serializers

from dashboard.models import Customer, Order, OrderItem, OrderPayment, ProductVariant


def generate_order_token():
    last_order = Order.objects.order_by('id').last()
    next_id = (last_order.id + 1) if last_order else 1
    return f"INV-{next_id:03d}"


@transaction.atomic
def create_order_from_checkout(data):
    cart = data.get('cart') or []
    if not cart:
        raise serializers.ValidationError({'cart': 'Cart is empty.'})

    customer = None
    customer_data = data.get('customer') or {}
    if customer_data.get('phone'):
        customer, _ = Customer.objects.get_or_create(
            phone=customer_data.get('phone'),
            defaults={'name': customer_data.get('name') or 'Walk-in Customer'},
        )
        if customer_data.get('name') and customer.name != customer_data.get('name'):
            customer.name = customer_data.get('name')
            customer.save(update_fields=['name'])

    order = Order.objects.create(
        token_number=generate_order_token(),
        customer=customer,
        total_amount=0,
        final_amount=0,
    )

    total_amount = Decimal('0')
    for cart_item in cart:
        variant = ProductVariant.objects.select_for_update().get(id=cart_item['variant_id'])
        qty = int(cart_item.get('quantity', 1))
        if qty <= 0:
            raise serializers.ValidationError({'quantity': 'Quantity must be greater than zero.'})
        if variant.stock < qty:
            raise serializers.ValidationError({
                'stock': f'Insufficient stock for {variant.product.name} ({variant.sku}).'
            })

        item_price = Decimal(str(cart_item.get('price', variant.price)))
        needs_stitching = bool(cart_item.get('needs_stitching', False))
        stitching_price = Decimal(str(cart_item.get('stitching_price', 0))) if needs_stitching else Decimal('0')

        OrderItem.objects.create(
            order=order,
            variant=variant,
            quantity=qty,
            price=item_price,
            cost_price=variant.cost_price,
            needs_stitching=needs_stitching,
            stitching_price=stitching_price,
            stitching_status='Pending' if needs_stitching else 'Not Applicable',
            delivery_date=cart_item.get('delivery_date') or None,
            notes=cart_item.get('notes') or None,
        )
        total_amount += (item_price * qty) + (stitching_price * qty)
        variant.stock -= qty
        variant.save(update_fields=['stock'])

    order.discount = Decimal(str(data.get('discount', 0) or 0))
    manual_total = data.get('manual_total')
    if manual_total and Decimal(str(manual_total)) > 0:
        manual_total_value = Decimal(str(manual_total))
        stitching_total = sum(item.stitching_price * item.quantity for item in order.items.all())
        order.final_amount = manual_total_value + stitching_total
        items = list(order.items.all())
        total_qty = sum(item.quantity for item in items)
        if total_qty:
            distributed_price = manual_total_value / Decimal(total_qty)
            for item in items:
                item.price = distributed_price
                item.save(update_fields=['price'])
    else:
        order.final_amount = max(total_amount - order.discount, Decimal('0'))

    amount_paid = data.get('amount_paid')
    order.amount_paid = Decimal(str(amount_paid)) if amount_paid not in (None, '') else order.final_amount
    if order.amount_paid >= order.final_amount:
        order.payment_status = 'Paid'
    elif order.amount_paid > 0:
        order.payment_status = 'Partial'
    else:
        order.payment_status = 'Unpaid'

    order.total_amount = sum(item.total_price for item in order.items.all())
    order.save()

    if order.amount_paid > 0:
        OrderPayment.objects.create(order=order, amount=order.amount_paid, note='Initial Payment')

    return order


@transaction.atomic
def add_order_payment(order, amount, note='Mobile payment'):
    amount = Decimal(str(amount))
    if amount <= 0:
        raise serializers.ValidationError({'amount': 'Amount must be greater than zero.'})
    if amount > order.balance_due:
        raise serializers.ValidationError({'amount': f'Amount exceeds balance due ({order.balance_due}).'})
    order.amount_paid += amount
    order.payment_status = 'Paid' if order.amount_paid >= order.final_amount else 'Partial'
    order.save(update_fields=['amount_paid', 'payment_status'])
    return OrderPayment.objects.create(order=order, amount=amount, note=note)

