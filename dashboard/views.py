from decimal import Decimal
from urllib.parse import urlencode
from django.shortcuts import render, redirect, get_object_or_404
from django.db import models
from django.db.models import ProtectedError
from django.db.models import Sum, Count
from django.utils import timezone
from django.utils.http import url_has_allowed_host_and_scheme
from datetime import timedelta, date
from django.db.models.functions import TruncDate, ExtractMonth, ExtractDay
from .models import Order, Product, Category, ProductVariant, Customer, OrderItem, Darzi, SubCategory, Expense, OrderPayment
from .forms import ProductForm, VariantForm, CategoryForm, SubCategoryForm, DarziForm, ExpenseForm
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import logout as session_logout
from django.shortcuts import resolve_url


def login_view(request):
    next_url = request.GET.get('next') or resolve_url('dashboard')
    if request.user.is_authenticated:
        return redirect(next_url)
    return render(request, 'dashboard/login.html', {'next_url': next_url})


def logout_view(request):
    session_logout(request)
    return redirect('login')


def _redirect_with_toast(request, message, toast_type='success'):
    next_url = request.POST.get('next') or request.GET.get('next') or resolve_url('products')
    if not url_has_allowed_host_and_scheme(next_url, allowed_hosts={request.get_host()}, require_https=request.is_secure()):
        next_url = resolve_url('products')

    separator = '&' if '?' in next_url else '?'
    query = urlencode({'toast_message': message, 'toast_type': toast_type})
    return redirect(f'{next_url}{separator}{query}')

def expenses_view(request):
    view_type = request.GET.get('view', 'monthly')
    selected_date_str = request.GET.get('date')
    today = timezone.now().date()

    # Parse date based on view_type
    if view_type == 'daily':
        base_date = timezone.datetime.strptime(selected_date_str, '%Y-%m-%d').date() if selected_date_str else today
        filters = {'date__date': base_date}
        exp_filters = {'date': base_date}
    elif view_type == 'yearly':
        year = int(selected_date_str) if selected_date_str else today.year
        base_date = date(year, 1, 1)
        filters = {'date__year': year}
        exp_filters = {'date__year': year}
    else: # monthly
        if selected_date_str:
            y, m = map(int, selected_date_str.split('-'))
            base_date = date(y, m, 1)
        else:
            base_date = today.replace(day=1)
        filters = {'date__year': base_date.year, 'date__month': base_date.month}
        exp_filters = {'date__year': base_date.year, 'date__month': base_date.month}

    # Calculations
    # Calculations using Payment-based accounting
    pay_filters = {k.replace('date__', 'date__'): v for k, v in filters.items()}
    total_sales = OrderPayment.objects.filter(**pay_filters).aggregate(Sum('amount'))['amount__sum'] or 0
    total_expenses = Expense.objects.filter(**exp_filters).aggregate(Sum('amount'))['amount__sum'] or 0
    
    # Cost of items sold in this period
    orders_in_period = Order.objects.filter(**filters)
    total_cost = sum([order.total_cost for order in orders_in_period])
    
    # Profit = Total Received - Total Cost
    total_profit = total_sales - total_cost
    net_profit = total_profit - total_expenses

    all_expenses = Expense.objects.all().order_by('-date')
    form = ExpenseForm(request.POST or None)
    if request.method == 'POST' and form.is_valid():
        form.save()
        return redirect('expenses')

    return render(request, 'dashboard/expenses.html', {
        'expenses': all_expenses,
        'form': form,
        'view_type': view_type,
        'base_date': base_date,
        'total_sales': total_sales,
        'total_expenses': total_expenses,
        'total_profit': total_profit,
        'net_profit': net_profit,
        'year_range': range(today.year - 5, today.year + 2),
    })

def dashboard_view(request):
    total_sales = OrderPayment.objects.aggregate(Sum('amount'))['amount__sum'] or 0
    total_orders = Order.objects.count()
    total_customers = Customer.objects.count()
    
    # Total Profit = Total Payments - Total Cost
    total_cost = sum([order.total_cost for order in Order.objects.all()])
    total_profit = total_sales - total_cost
    
    pending_stitching = OrderItem.objects.filter(needs_stitching=True).exclude(stitching_status='Delivered').count()
    
    recent_orders = Order.objects.order_by('-date')[:5]
    
    # Workflow stats
    workflow = {
        'pending': OrderItem.objects.filter(stitching_status='Pending').count(),
        'sent': OrderItem.objects.filter(stitching_status='Sent To Darzi').count(),
        'stitching': OrderItem.objects.filter(stitching_status='Stitching').count(),
        'ready': OrderItem.objects.filter(stitching_status='Ready').count(),
        'delivered': OrderItem.objects.filter(stitching_status='Delivered').count(),
    }

    # Low stock alerts
    low_stock_items = ProductVariant.objects.filter(stock__lt=10).select_related('product')[:5]

    # Sales Chart Logic
    period = request.GET.get('period', 'week')
    today = timezone.now().date()
    chart_data = []
    
    if period == 'year':
        months = [date(today.year, i, 1) for i in range(1, 13)]
        sales_qs = Order.objects.filter(date__year=today.year).annotate(
            month_idx=ExtractMonth('date')
        ).values('month_idx').annotate(total=Sum('final_amount'))
        
        sales_dict = {item['month_idx']: item['total'] for item in sales_qs}
        max_val = max(sales_dict.values()) if sales_dict else 1
        
        for i, m in enumerate(months, 1):
            total = float(sales_dict.get(i, 0))
            chart_data.append({
                'label': m.strftime('%b'),
                'total': total,
                'height': max((total / float(max_val or 1)) * 100, 5)
            })
            
    elif period == 'month':
        import calendar
        _, num_days = calendar.monthrange(today.year, today.month)
        days = [date(today.year, today.month, i) for i in range(1, num_days + 1)]
        
        sales_qs = Order.objects.filter(date__year=today.year, date__month=today.month).annotate(
            day_val=ExtractDay('date')
        ).values('day_val').annotate(total=Sum('final_amount'))
        
        sales_dict = {item['day_val']: item['total'] for item in sales_qs}
        max_val = max(sales_dict.values()) if sales_dict else 1
        
        for i, d in enumerate(days, 1):
            total = float(sales_dict.get(i, 0))
            chart_data.append({
                'label': str(i),
                'total': total,
                'height': max((total / float(max_val or 1)) * 100, 5)
            })
    else: # week
        last_7_days = [today - timedelta(days=i) for i in range(6, -1, -1)]
        sales_qs = Order.objects.filter(date__date__gte=last_7_days[0]).annotate(
            day=TruncDate('date')
        ).values('day').annotate(total=Sum('final_amount'))
        
        sales_dict = {item['day']: item['total'] for item in sales_qs}
        max_val = max(sales_dict.values()) if sales_dict else 1
        
        for day in last_7_days:
            total = float(sales_dict.get(day, 0))
            chart_data.append({
                'label': day.strftime('%a'),
                'total': total,
                'height': max((total / float(max_val or 1)) * 100, 5)
            })

    # Stats for the analysis card
    period_totals = [d['total'] for d in chart_data]
    analysis_stats = {
        'total': sum(period_totals),
        'avg': sum(period_totals) / len(period_totals) if period_totals else 0,
        'max': max(period_totals) if period_totals else 0,
    }

    context = {
        'total_sales': total_sales,
        'total_orders': total_orders,
        'total_customers': total_customers,
        'pending_stitching': pending_stitching,
        'recent_orders': recent_orders,
        'workflow': workflow,
        'low_stock_items': low_stock_items,
        'chart_data': chart_data,
        'current_period': period,
        'analysis_stats': analysis_stats,
    }
    return render(request, 'dashboard/index.html', context)

def pos_view(request):
    categories = Category.objects.all()
    products_qs = Product.objects.all().prefetch_related('variants')
    
    products_data = []
    for p in products_qs:
        variants = []
        for v in p.variants.all():
            variants.append({
                'id': v.id,
                'sku': v.sku,
                'color': v.color,
                'size': v.size,
                'price': float(v.price),
                'stock': v.stock,
                'image': v.image.url if v.image else None
            })
        
        products_data.append({
            'id': p.id,
            'name': p.name,
            'category': p.category.name if p.category else 'Uncategorized',
            'image': p.image.url if p.image else None,
            'is_handmade': p.is_handmade,
            'variants': variants
        })

    return render(request, 'dashboard/pos.html', {
        'categories': categories,
        'products_json': json.dumps(products_data)
    })

@csrf_exempt
def checkout(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        cart = data.get('cart', [])
        customer_data = data.get('customer', {})
        
        if not cart:
            return JsonResponse({'status': 'error', 'message': 'Cart is empty'}, status=400)

        # Create or get customer
        customer = None
        if customer_data.get('phone'):
            customer, created = Customer.objects.get_or_create(
                phone=customer_data.get('phone'),
                defaults={'name': customer_data.get('name')}
            )
        
        # Generate token
        last_order = Order.objects.order_by('id').last()
        next_id = (last_order.id + 1) if last_order else 1
        token = f"INV-{next_id:03d}"
        
        # Create Order
        order = Order.objects.create(
            token_number=token,
            customer=customer,
            total_amount=0,
            final_amount=0
        )
        
        total_amount = 0
        for item in cart:
            variant = ProductVariant.objects.get(id=item['variant_id'])
            qty = int(item.get('quantity', 1))
            item_price = float(item.get('price', variant.price))
            stitching_price = float(item.get('stitching_price', 0)) if item.get('needs_stitching') else 0
            
            OrderItem.objects.create(
                order=order,
                variant=variant,
                quantity=qty,
                price=item_price,
                cost_price=float(variant.cost_price),
                needs_stitching=item.get('needs_stitching', False),
                stitching_price=stitching_price,
                stitching_status='Pending' if item.get('needs_stitching') else 'Not Applicable'
            )
            
            total_amount += (item_price * qty) + (stitching_price * qty)
            
            # Deduct stock
            variant.stock -= qty
            variant.save()
            
        order.total_amount = total_amount
        order.discount = float(data.get('discount', 0))
        
        manual_total = data.get('manual_total')
        if manual_total and float(manual_total) > 0:
            m_total = float(manual_total)
            stitching_total = sum([item.stitching_price * item.quantity for item in order.items.all()])
            order.final_amount = m_total + float(stitching_total)
            
            # Distribute manual total across items so they don't show 0 on invoice
            items = list(order.items.all())
            if items:
                total_qty = sum([item.quantity for item in items])
                for item in items:
                    # Distribute proportionally by quantity
                    item.price = m_total / total_qty
                    item.save()
        else:
            order.final_amount = total_amount - order.discount
        
        # Payment handling
        amount_paid_str = data.get('amount_paid', None)
        if amount_paid_str is not None and amount_paid_str != '':
            order.amount_paid = float(amount_paid_str)
        else:
            order.amount_paid = order.final_amount # Default to full payment
            
        if order.amount_paid >= order.final_amount:
            order.payment_status = 'Paid'
        elif order.amount_paid > 0:
            order.payment_status = 'Partial'
        else:
            order.payment_status = 'Unpaid'
            
        # Recalculate subtotal to match the distributed manual total and stitching
        order.total_amount = sum([item.total_price for item in order.items.all()])
        order.save()
        
        # Record initial payment
        if order.amount_paid > 0:
            OrderPayment.objects.create(
                order=order,
                amount=order.amount_paid,
                note="Initial Payment"
            )
        
        return JsonResponse({'status': 'success', 'token': token, 'order_id': order.id})
    return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=400)

def invoice_view(request, order_id):
    order = get_object_or_404(Order, id=order_id)
    return render(request, 'dashboard/invoice.html', {'order': order})

def sales_list(request):
    from django.core.paginator import Paginator
    q = request.GET.get('q', '')
    page_num = request.GET.get('page', 1)
    orders_qs = Order.objects.all().order_by('-date')
    
    if q:
        orders_qs = orders_qs.filter(
            models.Q(token_number__icontains=q) | 
            models.Q(customer__name__icontains=q) |
            models.Q(customer__phone__icontains=q)
        )
    
    paginator = Paginator(orders_qs, 100)
    page_obj = paginator.get_page(page_num)
    
    return render(request, 'dashboard/sales.html', {
        'orders': page_obj,
        'page_obj': page_obj,
        'paginator': paginator,
        'q': q
    })

def dues_list(request):
    from django.core.paginator import Paginator
    q = request.GET.get('q', '')
    page_num = request.GET.get('page', 1)
    # Filter for orders with balance due
    orders_qs = Order.objects.exclude(payment_status='Paid').order_by('-date')
    
    if q:
        orders_qs = orders_qs.filter(
            models.Q(token_number__icontains=q) | 
            models.Q(customer__name__icontains=q) |
            models.Q(customer__phone__icontains=q)
        )
    
    paginator = Paginator(orders_qs, 100)
    page_obj = paginator.get_page(page_num)
    
    # Calculate total dues from ALL unpaid/partial orders (not just current search/page)
    # Actually, user might want total dues of the filtered list?
    # No, grand total is better.
    total_dues = sum([o.balance_due for o in Order.objects.exclude(payment_status='Paid')])
    
    return render(request, 'dashboard/dues.html', {
        'orders': page_obj,
        'page_obj': page_obj,
        'paginator': paginator,
        'total_dues': total_dues,
        'q': q
    })

def global_search_api(request):
    q = request.GET.get('q', '').strip()
    if not q:
        return JsonResponse({'results': []})
    
    results = []
    
    # 1. Search Products by name
    products = Product.objects.filter(name__icontains=q)[:5]
    for p in products:
        results.append({
            'type': 'Product',
            'title': p.name,
            'subtitle': p.category.name if p.category else 'Uncategorized',
            'url': f"/products/edit/{p.id}/"
        })
        
    # 2. Search Variants by color
    variants = ProductVariant.objects.filter(color__icontains=q).select_related('product')[:5]
    for v in variants:
        results.append({
            'type': 'Variant',
            'title': f"{v.product.name} ({v.color})",
            'subtitle': f"Size: {v.size} | Stock: {v.stock}",
            'url': f"/products/{v.product.id}/variants/"
        })
        
    # 3. Search Customers by name
    customers = Customer.objects.filter(name__icontains=q)[:5]
    for c in customers:
        results.append({
            'type': 'Customer',
            'title': c.name,
            'subtitle': c.phone if c.phone else 'No Phone',
            'url': f"/sales/" # Fallback to sales for customer view
        })
        
    # 4. Search Orders by customer name, token, or product name
    orders = Order.objects.filter(
        models.Q(customer__name__icontains=q) | 
        models.Q(token_number__icontains=q) |
        models.Q(items__variant__product__name__icontains=q)
    ).distinct()[:5]
    
    for o in orders:
        results.append({
            'type': 'Order',
            'id': o.id,
            'title': o.token_number,
            'subtitle': f"{o.customer.name if o.customer else 'Walk-in'} | Rs. {o.final_amount}",
            'url': f"/invoice/{o.id}/",
            'void_url': f"/order/void/{o.id}/",
            'payment_status': o.payment_status,
            'balance_due': float(o.balance_due)
        })
        
    return JsonResponse({'results': results})

def customer_list(request):
    from django.core.paginator import Paginator
    q = request.GET.get('q', '')
    page_num = request.GET.get('page', 1)

    # Get all customers with their order aggregates
    customers_qs = Customer.objects.annotate(
        total_orders=models.Count('order'),
        total_spent=models.Sum('order__final_amount'),
        total_paid=models.Sum('order__amount_paid')
    ).exclude(name__isnull=True, phone__isnull=True)

    if q:
        customers_qs = customers_qs.filter(
            models.Q(name__icontains=q) | models.Q(phone__icontains=q)
        )
    
    customers_qs = customers_qs.order_by('name')
    
    paginator = Paginator(customers_qs, 100)
    page_obj = paginator.get_page(page_num)

    # Calculate balance due in python to avoid complex F expressions if fields can be null
    customer_data = []
    for c in page_obj:
        spent = c.total_spent or 0
        paid = c.total_paid or 0
        balance = spent - paid
        customer_data.append({
            'id': c.id,
            'name': c.name,
            'phone': c.phone,
            'total_orders': c.total_orders,
            'total_spent': spent,
            'balance_due': balance
        })
        
    return render(request, 'dashboard/customers.html', {
        'customers': customer_data,
        'page_obj': page_obj,
        'paginator': paginator,
        'q': q
    })

def inventory_list(request):
    from django.core.paginator import Paginator

    # Get tab and page number from URL
    active_tab = request.GET.get('tab', 'control')
    page_num = request.GET.get('page', 1)
    q = request.GET.get('q', '')

    # Products for Stock Control tab (Paginate 100 per page as requested)
    products_qs = Product.objects.all().prefetch_related('variants').order_by('name')
    if q:
        products_qs = products_qs.filter(name__icontains=q)
    
    products_paginator = Paginator(products_qs, 100)
    
    # Variants for Stock Report tab (Paginate 100 per page)
    variants_qs = ProductVariant.objects.select_related('product').order_by('product__name', 'color')
    if q:
        variants_qs = variants_qs.filter(
            models.Q(product__name__icontains=q) | models.Q(sku__icontains=q) | models.Q(color__icontains=q)
        )
    
    variants_paginator = Paginator(variants_qs, 100)

    if active_tab == 'report':
        page_obj = variants_paginator.get_page(page_num)
        products_page_obj = products_paginator.get_page(1)
    else:
        products_page_obj = products_paginator.get_page(page_num)
        page_obj = variants_paginator.get_page(1)

    # Add calculated total value to each variant for the report
    for variant in page_obj:
        buying_price = float(variant.cost_price) if variant.cost_price > 0 else float(variant.price)
        variant.total_value = float(variant.stock) * buying_price

    # Calculate totals for current page variants
    page_totals = {
        'total_stock': sum(v.stock for v in page_obj),
        'total_value': sum(float(v.stock) * (float(v.cost_price) if v.cost_price > 0 else float(v.price)) for v in page_obj)
    }

    # Calculate grand totals across all variants
    all_totals = {
        'total_stock': sum(v.stock for v in variants_qs),
        'total_value': sum(float(v.stock) * (float(v.cost_price) if v.cost_price > 0 else float(v.price)) for v in variants_qs)
    }

    return render(request, 'dashboard/inventory.html', {
        'active_tab': active_tab,
        'products': products_page_obj,
        'products_paginator': products_paginator,
        'page_obj': page_obj,
        'paginator': variants_paginator,
        'page_totals': page_totals,
        'all_totals': all_totals,
    })

@csrf_exempt
def update_variant_stock(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            variant_id = data.get('variant_id')
            new_stock = data.get('stock')
            
            variant = ProductVariant.objects.get(id=variant_id)
            variant.stock = int(new_stock)
            variant.save()
            
            return JsonResponse({'status': 'success', 'message': 'Stock updated successfully'})
        except Exception as e:
            return JsonResponse({'status': 'error', 'message': str(e)}, status=400)
    return JsonResponse({'status': 'error', 'message': 'Invalid request method'}, status=405)

def get_notifications_api(request):
    notifications = []
    
    # 1. Low stock alerts (assume <= 3 is low)
    low_stock_variants = ProductVariant.objects.filter(stock__lte=3).select_related('product')
    for v in low_stock_variants:
        notifications.append({
            'id': f"stock_{v.id}",
            'type': 'alert',
            'title': 'Low Stock Alert',
            'message': f"{v.product.name} ({v.color}, {v.size}) has only {v.stock} left in stock.",
            'time': 'Just now',
            'timestamp': timezone.now().timestamp(),
            'url': f"/inventory/"
        })
        
    # 2. Recent orders (last 5)
    recent_orders = Order.objects.all().order_by('-date')[:5]
    for o in recent_orders:
        notifications.append({
            'id': f"order_{o.id}",
            'type': 'info',
            'title': 'New Order Placed',
            'message': f"Order #{o.token_number} placed for Rs. {o.final_amount}.",
            'time': o.date.strftime("%b %d, %I:%M %p"),
            'timestamp': o.date.timestamp(),
            'url': f"/invoice/{o.id}/"
        })
        
    return JsonResponse({'notifications': notifications, 'unread_count': len(notifications)})

def product_list(request):
    from django.core.paginator import Paginator
    page_num = request.GET.get('page', 1)
    q = request.GET.get('q', '')
    
    products_qs = Product.objects.all().select_related('category').prefetch_related('variants').order_by('-created_at')
    if q:
        products_qs = products_qs.filter(name__icontains=q)
        
    categories = Category.objects.all().prefetch_related('subcategories')
    
    paginator = Paginator(products_qs, 100)
    page_obj = paginator.get_page(page_num)
    
    if request.method == 'POST':
        # ... existing category logic ...
        if 'add_category' in request.POST:
            form = CategoryForm(request.POST)
            if form.is_valid():
                form.save()
                return redirect('products')
        elif 'add_subcategory' in request.POST:
            form = SubCategoryForm(request.POST)
            if form.is_valid():
                form.save()
                return redirect('products')
    
    cat_form = CategoryForm()
    sub_form = SubCategoryForm()
    
    return render(request, 'dashboard/products.html', {
        'products': page_obj,
        'page_obj': page_obj,
        'paginator': paginator,
        'categories': categories,
        'cat_form': cat_form,
        'sub_form': sub_form
    })

def add_product(request):
    if request.method == 'POST':
        form = ProductForm(request.POST, request.FILES)
        if form.is_valid():
            product = form.save(commit=False)
            
            cat_name = form.cleaned_data.get('category_name')
            subcat_name = form.cleaned_data.get('subcategory_name')
            
            if cat_name:
                category, created = Category.objects.get_or_create(name=cat_name)
                product.category = category
                
                if subcat_name:
                    subcategory, created = SubCategory.objects.get_or_create(category=category, name=subcat_name)
                    product.subcategory = subcategory
            
            product.save()
            
            # Handle selected colors and stocks from JSON
            color_stocks_json = request.POST.get('color_stocks_json', '{}')
            color_stocks = json.loads(color_stocks_json)
            
            cost_price = form.cleaned_data.get('cost_price') or 0
            
            if color_stocks:
                for color, stock in color_stocks.items():
                    ProductVariant.objects.create(
                        product=product,
                        color=color,
                        sku=f"{product.id}-{color[:3].upper()}-{timezone.now().strftime('%M%S')}",
                        size='Standard',
                        price=0, 
                        cost_price=cost_price,
                        stock=int(stock or 0)
                    )
            elif cost_price:
                # Fallback to default if no colors selected
                ProductVariant.objects.create(
                    product=product,
                    sku=f"{product.id}-DEF",
                    color="Default",
                    size="Standard",
                    price=0,
                    cost_price=cost_price,
                    stock=form.cleaned_data.get('stock') or 0
                )
            
            return redirect('products')
    else:
        form = ProductForm()
    
    all_categories = Category.objects.all()
    all_subcategories = SubCategory.objects.all()
    return render(request, 'dashboard/product_form.html', {
        'form': form, 
        'title': 'Add Product',
        'all_categories': all_categories,
        'all_subcategories': all_subcategories
    })

def edit_product(request, pk):
    product = get_object_or_404(Product, pk=pk)
    if request.method == 'POST':
        form = ProductForm(request.POST, request.FILES, instance=product)
        if form.is_valid():
            p = form.save(commit=False)
            
            cat_name = form.cleaned_data.get('category_name')
            subcat_name = form.cleaned_data.get('subcategory_name')
            
            if cat_name:
                category, created = Category.objects.get_or_create(name=cat_name)
                p.category = category
                
                if subcat_name:
                    subcategory, created = SubCategory.objects.get_or_create(category=category, name=subcat_name)
                    p.subcategory = subcategory
            
            p.save()

            # Handle selected colors and stocks from JSON
            color_stocks_json = request.POST.get('color_stocks_json', '{}')
            color_stocks = json.loads(color_stocks_json)
            
            cost_price = form.cleaned_data.get('cost_price') or 0
            
            # Clear existing variants and recreate (or update)
            # Simplest for now is to update existing and add new
            existing_variants = {v.color: v for v in p.variants.all()}
            
            if color_stocks:
                for color, stock in color_stocks.items():
                    if color in existing_variants:
                        variant = existing_variants[color]
                        variant.stock = int(stock or 0)
                        variant.save()
                        del existing_variants[color]
                    else:
                        ProductVariant.objects.create(
                            product=p,
                            color=color,
                            sku=f"{p.id}-{color[:3].upper()}-{timezone.now().strftime('%M%S')}",
                            size='Standard',
                            price=cost_price,
                            cost_price=cost_price,
                            stock=int(stock or 0)
                        )
                
                # Delete variants that were removed
                for variant in existing_variants.values():
                    variant.delete()
            
            return redirect('products')
    else:
        initial_data = {}
        if product.category:
            initial_data['category_name'] = product.category.name
        if product.subcategory:
            initial_data['subcategory_name'] = product.subcategory.name
        
        # Pre-fill selected colors based on existing variants
        initial_data['available_colors'] = list(product.variants.values_list('color', flat=True))
        
        form = ProductForm(instance=product, initial=initial_data)
    
    all_categories = Category.objects.all()
    all_subcategories = SubCategory.objects.all()
    return render(request, 'dashboard/product_form.html', {
        'form': form, 
        'title': 'Edit Product',
        'all_categories': all_categories,
        'all_subcategories': all_subcategories
    })

def delete_product(request, pk):
    product = get_object_or_404(Product, pk=pk)
    if request.method == 'POST':
        try:
            product.delete()
            return _redirect_with_toast(request, 'Product deleted successfully', 'success')
        except ProtectedError:
            return _redirect_with_toast(
                request,
                'This product cannot be deleted because it is linked to existing orders.',
                'error'
            )
        except Exception:
            return _redirect_with_toast(
                request,
                'Failed to delete product. Please try again.',
                'error'
            )
    return redirect('products')

def manage_variants(request, product_pk):
    product = get_object_or_404(Product, pk=product_pk)
    variants = product.variants.all()
    if request.method == 'POST':
        form = VariantForm(request.POST, request.FILES)
        if form.is_valid():
            variant = form.save(commit=False)
            variant.product = product
            if variant.cost_price == 0:
                variant.cost_price = variant.price
            variant.save()
            return redirect('manage_variants', product_pk=product.pk)
    else:
        form = VariantForm()
    return render(request, 'dashboard/manage_variants.html', {'product': product, 'variants': variants, 'form': form})

def delete_variant(request, pk):
    variant = get_object_or_404(ProductVariant, pk=pk)
    product_pk = variant.product.pk
    variant.delete()
    return redirect('manage_variants', product_pk=product_pk)

def category_list(request):
    categories = Category.objects.all().prefetch_related('subcategories')
    if request.method == 'POST':
        if 'add_category' in request.POST:
            form = CategoryForm(request.POST)
            if form.is_valid():
                form.save()
                return redirect('category_list')
        elif 'add_subcategory' in request.POST:
            form = SubCategoryForm(request.POST)
            if form.is_valid():
                form.save()
                return redirect('category_list')
    
    cat_form = CategoryForm()
    sub_form = SubCategoryForm()
    return render(request, 'dashboard/categories.html', {
        'categories': categories,
        'cat_form': cat_form,
        'sub_form': sub_form
    })

def delete_category(request, pk):
    category = get_object_or_404(Category, pk=pk)
    category.delete()
    return redirect('products')

def delete_subcategory(request, pk):
    subcategory = get_object_or_404(SubCategory, pk=pk)
    subcategory.delete()
    return redirect('products')

def void_order(request, pk):
    order = get_object_or_404(Order, pk=pk)
    if request.method == 'POST':
        # Return stock
        for item in order.items.all():
            variant = item.variant
            if variant:
                variant.stock += item.quantity
                variant.save()
        
        # Delete order (removes from sales and profit)
        order.delete()
        
        if request.GET.get('action') == 'replace':
            return redirect('pos')
        return redirect('sales')
    return render(request, 'dashboard/order_confirm_void.html', {'order': order})

def void_orders_list(request):
    orders = Order.objects.all().order_by('-date')
    return render(request, 'dashboard/void_orders_list.html', {'orders': orders})

def tailoring_view(request):
    from django.core.paginator import Paginator
    page_num = request.GET.get('page', 1)
    q = request.GET.get('q', '')

    darzis = Darzi.objects.all().annotate(
        ongoing_count=Count('orderitem', filter=models.Q(orderitem__stitching_status__in=['Sent To Darzi', 'Cutting', 'Stitching'])),
        completed_count=Count('orderitem', filter=models.Q(orderitem__stitching_status='Ready'))
    )
    stitching_orders = OrderItem.objects.filter(needs_stitching=True).select_related('order', 'variant__product', 'darzi').order_by('-order__date')
    
    if q:
        stitching_orders = stitching_orders.filter(
            models.Q(order__token_number__icontains=q) | 
            models.Q(variant__product__name__icontains=q) |
            models.Q(order__customer__name__icontains=q)
        )
        
    paginator = Paginator(stitching_orders, 100)
    page_obj = paginator.get_page(page_num)
    
    if request.method == 'POST':
        form = DarziForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('tailoring')
    else:
        form = DarziForm()
    
    return render(request, 'dashboard/tailoring.html', {
        'darzis': darzis,
        'orders': page_obj,
        'page_obj': page_obj,
        'paginator': paginator,
        'form': form,
        'q': q
    })

def delete_darzi(request, pk):
    darzi = get_object_or_404(Darzi, pk=pk)
    darzi.delete()
    return redirect('tailoring')

@csrf_exempt
def update_stitching_status(request, item_id):
    if request.method == 'POST':
        data = json.loads(request.body)
        status = data.get('status')
        item = OrderItem.objects.get(id=item_id)
        item.stitching_status = status
        item.save()
        
        # If status is Delivered, and there is a balance due, mark as paid
        if status == 'Delivered':
            order = item.order
            if order.balance_due > 0:
                amount_to_pay = order.balance_due
                OrderPayment.objects.create(
                    order=order,
                    amount=amount_to_pay,
                    note=f"Cleared on {status} ({item.variant.product.name})"
                )
                order.amount_paid += amount_to_pay
                order.payment_status = 'Paid'
                order.save()
                
        return JsonResponse({'status': 'success'})
    return JsonResponse({'status': 'error'}, status=400)

@csrf_exempt
def assign_darzi(request, item_id):
    if request.method == 'POST':
        data = json.loads(request.body)
        darzi_id = data.get('darzi_id')
        item = OrderItem.objects.get(id=item_id)
        item.darzi_id = darzi_id
        item.save()
        return JsonResponse({'status': 'success'})
    return JsonResponse({'status': 'error'}, status=400)

@csrf_exempt
def update_delivery_date(request, item_id):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            delivery_date = data.get('delivery_date')
            item = OrderItem.objects.get(id=item_id)
            if delivery_date:
                item.delivery_date = delivery_date
            else:
                item.delivery_date = None
            item.save()
            return JsonResponse({'status': 'success'})
        except Exception as e:
            return JsonResponse({'status': 'error', 'message': str(e)}, status=400)
    return JsonResponse({'status': 'error', 'message': 'Invalid request method'}, status=405)

@csrf_exempt
def update_payment(request, order_id):
    if request.method == 'POST':
        try:
            order = get_object_or_404(Order, id=order_id)
            data = json.loads(request.body)
            additional_amount = Decimal(str(data.get('amount', 0)))
            
            if additional_amount <= 0:
                return JsonResponse({'status': 'error', 'message': 'Amount must be greater than zero'})
                
            if additional_amount > order.balance_due:
                return JsonResponse({'status': 'error', 'message': f'Amount exceeds balance due (Rs. {order.balance_due})'})
                
            order.amount_paid += additional_amount
            
            if order.amount_paid >= order.final_amount:
                order.payment_status = 'Paid'
            elif order.amount_paid > 0:
                order.payment_status = 'Partial'
            else:
                order.payment_status = 'Unpaid'
                
            order.save()
            
            # Record installment payment
            OrderPayment.objects.create(
                order=order,
                amount=additional_amount,
                note="Installment Payment"
            )
            
            return JsonResponse({
                'status': 'success', 
                'message': f'Payment of Rs. {additional_amount} added successfully!',
                'new_balance': float(order.balance_due),
                'new_status': order.payment_status
            })
        except Exception as e:
            return JsonResponse({'status': 'error', 'message': str(e)}, status=400)
    return JsonResponse({'status': 'error', 'message': 'Invalid request method'}, status=405)
