from datetime import date, timedelta

from django.db.models import Count, Sum, F
from django.db.models.functions import ExtractDay, ExtractMonth, TruncDate
from django.utils import timezone
from rest_framework import permissions, response, views, viewsets

from dashboard.models import Customer, Expense, Order, OrderItem, OrderPayment, ProductVariant
from .serializers import ExpenseSerializer


class SalesReportView(views.APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        period = request.query_params.get('period', 'week')
        today = timezone.now().date()
        chart_data = []

        if period == 'year':
            sales_qs = Order.objects.filter(date__year=today.year).annotate(month_idx=ExtractMonth('date')).values('month_idx').annotate(total=Sum('final_amount'))
            sales = {row['month_idx']: row['total'] for row in sales_qs}
            for month in range(1, 13):
                chart_data.append({'label': date(today.year, month, 1).strftime('%b'), 'total': float(sales.get(month, 0) or 0)})
        elif period == 'month':
            import calendar
            _, days = calendar.monthrange(today.year, today.month)
            sales_qs = Order.objects.filter(date__year=today.year, date__month=today.month).annotate(day_val=ExtractDay('date')).values('day_val').annotate(total=Sum('final_amount'))
            sales = {row['day_val']: row['total'] for row in sales_qs}
            for day in range(1, days + 1):
                chart_data.append({'label': str(day), 'total': float(sales.get(day, 0) or 0)})
        else:
            start = today - timedelta(days=6)
            sales_qs = Order.objects.filter(date__date__gte=start).annotate(day=TruncDate('date')).values('day').annotate(total=Sum('final_amount'))
            sales = {row['day']: row['total'] for row in sales_qs}
            for offset in range(7):
                day = start + timedelta(days=offset)
                chart_data.append({'label': day.strftime('%a'), 'total': float(sales.get(day, 0) or 0)})

        totals = [item['total'] for item in chart_data]
        return response.Response({
            'period': period,
            'total_sales': float(sum(totals)),
            'average_sales': float(sum(totals) / len(totals)) if totals else 0,
            'max_sales': float(max(totals)) if totals else 0,
            'chart': chart_data,
        })


class AnalyticsSummaryView(views.APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        today = timezone.now().date()
        
        # Optimized Aggregations (Single DB queries instead of loops)
        total_revenue = OrderPayment.objects.aggregate(total=Sum('amount'))['total'] or 0
        
        # Calculate total cost using database aggregation on OrderItem
        # This is much faster than looping through all orders in Python
        total_cost = OrderItem.objects.aggregate(
            total=Sum(F('cost_price') * F('quantity'))
        )['total'] or 0
        
        total_expenses = Expense.objects.aggregate(total=Sum('amount'))['total'] or 0

        # Stitching Workflow counts (Efficient grouping)
        workflow_qs = OrderItem.objects.filter(needs_stitching=True).values('stitching_status').annotate(count=Count('id'))
        workflow_map = {row['stitching_status']: row['count'] for row in workflow_qs}
        
        workflow = {
            'pending': workflow_map.get('Pending', 0),
            'sent': workflow_map.get('Sent To Darzi', 0),
            'stitching': workflow_map.get('Stitching', 0),
            'ready': workflow_map.get('Ready', 0),
            'delivered': workflow_map.get('Delivered', 0),
        }

        # Recent 5 orders (Optimized select_related)
        recent_orders_qs = Order.objects.select_related('customer').only(
            'id', 'token_number', 'customer__name', 'final_amount', 'payment_status', 'date'
        ).order_by('-date')[:5]
        
        recent_orders = []
        for o in recent_orders_qs:
            recent_orders.append({
                'id': o.id,
                'token_number': o.token_number,
                'customer_name': o.customer.name if o.customer else 'Walk-in',
                'final_amount': float(o.final_amount),
                'payment_status': o.payment_status,
                'date': o.date.strftime('%b %d, %I:%M %p'),
            })

        # Low stock items (stock < 10)
        low_stock_qs = ProductVariant.objects.filter(stock__lt=10).select_related('product').only(
            'product__name', 'color', 'size', 'stock'
        )[:6]
        low_stock_items = []
        for v in low_stock_qs:
            low_stock_items.append({
                'product_name': v.product.name,
                'color': v.color,
                'size': v.size,
                'stock': v.stock,
            })

        return response.Response({
            'total_revenue': float(total_revenue),
            'total_orders': Order.objects.count(),
            'total_customers': Customer.objects.count(),
            'total_profit': float(total_revenue - total_cost),
            'net_profit': float(total_revenue - total_cost - total_expenses),
            'pending_stitching': OrderItem.objects.filter(needs_stitching=True).exclude(stitching_status='Delivered').count(),
            'low_stock_count': ProductVariant.objects.filter(stock__lte=3).count(),
            'revenue_today': float(OrderPayment.objects.filter(date__date=today).aggregate(total=Sum('amount'))['total'] or 0),
            'workflow': workflow,
            'recent_orders': recent_orders,
            'low_stock_items': low_stock_items,
        })


class ExpenseViewSet(viewsets.ModelViewSet):
    queryset = Expense.objects.all().order_by('-date')
    serializer_class = ExpenseSerializer
    permission_classes = (permissions.IsAuthenticated,)
    search_fields = ('category', 'note')
    filterset_fields = ('date',)


