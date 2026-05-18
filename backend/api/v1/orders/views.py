from rest_framework import decorators, permissions, response, status, viewsets

from backend.api.v1.services import add_order_payment
from dashboard.models import Darzi, Order, OrderItem

from .serializers import DarziSerializer, OrderItemSerializer, OrderSerializer, PaymentCreateSerializer


class OrderViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Order.objects.select_related('customer').prefetch_related(
        'items__variant__product', 'payments'
    ).order_by('-date')
    serializer_class = OrderSerializer
    permission_classes = (permissions.IsAuthenticated,)
    search_fields = ('token_number', 'customer__name', 'customer__phone', 'items__variant__product__name')
    ordering_fields = ('date', 'final_amount', 'payment_status')

    @decorators.action(detail=True, methods=['post'])
    def payment(self, request, pk=None):
        order = self.get_object()
        serializer = PaymentCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        if not request.user.is_staff:
            return response.Response({'detail': 'Staff access required.'}, status=status.HTTP_403_FORBIDDEN)
        add_order_payment(order, serializer.validated_data['amount'], serializer.validated_data.get('note') or 'Mobile payment')
        return response.Response(OrderSerializer(order, context={'request': request}).data, status=status.HTTP_200_OK)

    @decorators.action(detail=True, methods=['patch'])
    def status(self, request, pk=None):
        order = self.get_object()
        if not request.user.is_staff:
            return response.Response({'detail': 'Staff access required.'}, status=status.HTTP_403_FORBIDDEN)
        payment_status = request.data.get('payment_status')
        valid_statuses = {'Paid', 'Partial', 'Unpaid'}
        if payment_status not in valid_statuses:
            return response.Response({'payment_status': 'Invalid status.'}, status=status.HTTP_400_BAD_REQUEST)
        order.payment_status = payment_status
        order.save(update_fields=['payment_status'])
        return response.Response(OrderSerializer(order, context={'request': request}).data)


class DarziViewSet(viewsets.ModelViewSet):
    queryset = Darzi.objects.all().order_by('name')
    serializer_class = DarziSerializer
    permission_classes = (permissions.IsAuthenticated,)


class OrderItemViewSet(viewsets.ModelViewSet):
    queryset = OrderItem.objects.select_related('order', 'variant__product', 'darzi').order_by('-order__date')
    serializer_class = OrderItemSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_queryset(self):
        qs = super().get_queryset()
        if self.request.query_params.get('tailoring') == 'true':
            qs = qs.filter(needs_stitching=True).exclude(stitching_status='Delivered')
        return qs

    @decorators.action(detail=True, methods=['post'])
    def status(self, request, pk=None):
        item = self.get_object()
        new_status = request.data.get('status')
        if not new_status:
            return response.Response({'status': 'Required.'}, status=status.HTTP_400_BAD_REQUEST)
        item.stitching_status = new_status
        item.save(update_fields=['stitching_status'])
        return response.Response(OrderItemSerializer(item, context={'request': request}).data)

    @decorators.action(detail=True, methods=['post'])
    def assign(self, request, pk=None):
        item = self.get_object()
        darzi_id = request.data.get('darzi_id')
        if not darzi_id:
            return response.Response({'darzi_id': 'Required.'}, status=status.HTTP_400_BAD_REQUEST)
        item.darzi_id = darzi_id
        item.save(update_fields=['darzi_id'])
        return response.Response(OrderItemSerializer(item, context={'request': request}).data)
