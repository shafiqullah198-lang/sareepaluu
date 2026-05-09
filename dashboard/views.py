from decimal import Decimal
from django.shortcuts import render, redirect, get_object_or_404
from django.db import models
from django.db.models import Sum, Count
from django.utils import timezone
from datetime import timedelta, date
from django.db.models.functions import TruncDate
from .models import Order, Product, Category, ProductVariant, Customer, OrderItem, Darzi, SubCategory, Expense, OrderPayment
from .forms import ProductForm, VariantForm, CategoryForm, SubCategoryForm, DarziForm, ExpenseForm
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

def expenses_view(request):
    # Filter by month/year if provided, else current
    selected_month = request.GET.get('month') # expected format YYYY-MM
    selected_year = request.GET.get('year')   # expected format YYYY
    today = timezone.now().date()
    
    if selected_month:
        try:
            year_part, month_part = map(int, selected_month.split('-'))
            base_date = date(year_part, month_part, 1)
        except:
            base_date = today.replace(day=1)
    elif selected_year:
        try:
            base_date = date(int(selected_year), today.month, 1)
        except:
            base_date = today.replace(day=1)
    else:
        base_date = today.replace(day=1)

    # All expenses for the log table
    all_expenses = Expense.objects.all().order_by('-date')
    
    # Filtered Expenses (Monthly)
    month_expenses_qs = Expense.objects.filter(date__year=base_date.year, date__month=base_date.month)
    month_out = month_expenses_qs.aggregate(Sum('amount'))['amount__sum'] or 0
    
    # Filtered Sales (Monthly)
    month_sales_qs = Order.objects.filter(date__year=base_date.year, date__month=base_date.month)
    month_in = month_sales_qs.aggregate(Sum('final_amount'))['final_amount__sum'] or 0
    
    # Today stats
    today_out = Expense.objects.filter(date=today).aggregate(Sum('amount'))['amount__sum'] or 0
    today_in = Order.objects.filter(date__date=today).aggregate(Sum('final_amount'))['final_amount__sum'] or 0
    
    # Yearly stats
    year_out = Expense.objects.filter(date__year=base_date.year).aggregate(Sum('amount'))['amount__sum'] or 0
    year_in = Order.objects.filter(date__year=base_date.year).aggregate(Sum('final_amount'))['final_amount__sum'] or 0

    if request.method == 'POST':
        form = ExpenseForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('expenses')
    else:
        form = ExpenseForm()
        
    return render(request, 'dashboard/expenses.html', {
        'expenses': all_expenses,
        'form': form,
        'selected_month': base_date.strftime('%Y-%m'),
        'selected_year_val': base_date.year,
        'year_range': range(today.year - 5, today.year + 2),
        'today_in': today_in,
        'today_out': today_out,
        'month_in': month_in,
        'month_out': month_out,
        'year_in': year_in,
        'year_out': year_out,
        'net_month': month_in - month_out,
        'net_year': year_in - year_out
    })

def dashboard_view(request):
    total_sales = Order.objects.aggregate(Sum('final_amount'))['final_amount__sum'] or 0
    total_orders = Order.objects.count()
    total_customers = Customer.objects.count()
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

    # Generate last 7 days sales data for chart
    today = timezone.now().date()
    last_7_days = [today - timedelta(days=i) for i in range(6, -1, -1)]
    
    sales_qs = Order.objects.filter(date__date__gte=last_7_days[0]).annotate(
        day=TruncDate('date')
    ).values('day').annotate(total=Sum('final_amount'))
    
    sales_dict = {item['day']: item['total'] for item in sales_qs}
    
    max_sale = max([sales_dict.get(day, 0) for day in last_7_days]) if sales_dict else 1
    if max_sale == 0:
        max_sale = 1
        
    chart_data = []
    for day in last_7_days:
        total = float(sales_dict.get(day, 0))
        percentage = max((total / float(max_sale)) * 100, 5) # minimum 5% height for visual effect
        chart_data.append({
            'day_name': day.strftime('%a'),
            'total': total,
            'height': percentage
        })

    context = {
        'total_sales': total_sales,
        'total_orders': total_orders,
        'total_customers': total_customers,
        'pending_stitching': pending_stitching,
        'recent_orders': recent_orders,
        'workflow': workflow,
        'low_stock_items': low_stock_items,
        'chart_data': chart_data,
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
            qty = item.get('quantity', 1)
            stitching_price = float(item.get('stitching_price', 0)) if item.get('needs_stitching') else 0
            
            OrderItem.objects.create(
                order=order,
                variant=variant,
                quantity=qty,
                price=variant.price,
                needs_stitching=item.get('needs_stitching', False),
                stitching_price=stitching_price,
                stitching_status='Pending' if item.get('needs_stitching') else 'Not Applicable'
            )
            
            total_amount += (float(variant.price) * qty) + stitching_price
            
            # Deduct stock
            variant.stock -= qty
            variant.save()
            
        order.total_amount = total_amount
        order.final_amount = total_amount # Simplified for now
        
        # Payment handling
        amount_paid_str = data.get('amount_paid', None)
        if amount_paid_str is not None and amount_paid_str != '':
            order.amount_paid = float(amount_paid_str)
        else:
            order.amount_paid = total_amount # Default to full payment
            
        if order.amount_paid >= order.final_amount:
            order.payment_status = 'Paid'
        elif order.amount_paid > 0:
            order.payment_status = 'Partial'
        else:
            order.payment_status = 'Unpaid'
            
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
    orders = Order.objects.all().order_by('-date')
    return render(request, 'dashboard/sales.html', {'orders': orders})

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
            'subtitle': f"{o.customer.name if o.customer else 'Walk-in'} | Rs. {o.balance_due} Due",
            'url': f"/invoice/{o.id}/",
            'payment_status': o.payment_status,
            'balance_due': float(o.balance_due)
        })
        
    return JsonResponse({'results': results})

def customer_list(request):
    # Get all customers with their order aggregates
    customers = Customer.objects.annotate(
        total_orders=models.Count('order'),
        total_spent=models.Sum('order__final_amount'),
        total_paid=models.Sum('order__amount_paid')
    ).exclude(name__isnull=True, phone__isnull=True)  # Exclude pure walk-ins if they have no details
    
    # Calculate balance due in python to avoid complex F expressions if fields can be null
    customer_data = []
    for c in customers:
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
        
    return render(request, 'dashboard/customers.html', {'customers': customer_data})

def inventory_list(request):
    products = Product.objects.all().prefetch_related('variants')
    return render(request, 'dashboard/inventory.html', {'products': products})

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
    products = Product.objects.all().select_related('category').prefetch_related('variants')
    return render(request, 'dashboard/products.html', {'products': products})

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
            
            # Handle initial variant
            price = form.cleaned_data.get('price')
            stock = form.cleaned_data.get('stock')
            if price or stock:
                ProductVariant.objects.create(
                    product=product,
                    sku=f"{product.id}-DEF",
                    color="Default",
                    size="Standard",
                    price=price or 0,
                    stock=stock or 0
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
            return redirect('products')
    else:
        initial_data = {}
        if product.category:
            initial_data['category_name'] = product.category.name
        if product.subcategory:
            initial_data['subcategory_name'] = product.subcategory.name
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
        product.delete()
        return redirect('products')
    return render(request, 'dashboard/product_confirm_delete.html', {'product': product})

def manage_variants(request, product_pk):
    product = get_object_or_404(Product, pk=product_pk)
    variants = product.variants.all()
    if request.method == 'POST':
        form = VariantForm(request.POST, request.FILES)
        if form.is_valid():
            variant = form.save(commit=False)
            variant.product = product
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
    return redirect('category_list')

def delete_subcategory(request, pk):
    subcategory = get_object_or_404(SubCategory, pk=pk)
    subcategory.delete()
    return redirect('category_list')

def tailoring_view(request):
    darzis = Darzi.objects.all().annotate(
        ongoing_count=Count('orderitem', filter=models.Q(orderitem__stitching_status__in=['Sent To Darzi', 'Cutting', 'Stitching'])),
        completed_count=Count('orderitem', filter=models.Q(orderitem__stitching_status='Ready'))
    )
    stitching_orders = OrderItem.objects.filter(needs_stitching=True).select_related('order', 'variant__product', 'darzi').order_by('-order__date')
    
    if request.method == 'POST':
        form = DarziForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('tailoring')
    else:
        form = DarziForm()
    
    return render(request, 'dashboard/tailoring.html', {
        'darzis': darzis,
        'orders': stitching_orders,
        'form': form
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
