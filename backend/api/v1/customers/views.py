from django.db.models import Count, Sum
from rest_framework import decorators, permissions, response, viewsets

from backend.api.permissions.classes import IsStaffOrReadOnly
from dashboard.models import Customer, Order

from .serializers import CustomerDetailSerializer, CustomerSerializer


class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.annotate(
        total_orders=Count('order'),
        total_spent=Sum('order__final_amount'),
        total_paid=Sum('order__amount_paid'),
    ).order_by('name')
    permission_classes = (IsStaffOrReadOnly,)
    search_fields = ('name', 'phone')
    ordering_fields = ('name', 'id')

    @decorators.action(detail=False, methods=['get'])
    def dues(self, request):
        # Customers with at least one unpaid or partial order
        unpaid_orders = Order.objects.exclude(payment_status='Paid').values_list('customer_id', flat=True).distinct()
        customers = Customer.objects.filter(id__in=unpaid_orders)
        serializer = CustomerSerializer(customers, many=True, context={'request': request})
        return response.Response(serializer.data)

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return CustomerDetailSerializer
        return CustomerSerializer
