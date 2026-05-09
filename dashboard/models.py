from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator

class Category(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    
    def __str__(self):
        return self.name

class SubCategory(models.Model):
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='subcategories')
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.category.name} - {self.name}"

class Product(models.Model):
    name = models.CharField(max_length=200)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True)
    subcategory = models.ForeignKey(SubCategory, on_delete=models.SET_NULL, null=True, blank=True)
    image = models.ImageField(upload_to='products/', null=True, blank=True)
    is_handmade = models.BooleanField(default=False)
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class ProductVariant(models.Model):
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='variants')
    sku = models.CharField(max_length=50, unique=True)
    color = models.CharField(max_length=50)
    size = models.CharField(max_length=20)
    price = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    stock = models.IntegerField(default=0)
    image = models.ImageField(upload_to='variants/', blank=True, null=True)

    def __str__(self):
        return f"{self.product.name} - {self.color} - {self.size}"

class Darzi(models.Model):
    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=20, blank=True, null=True)
    active = models.BooleanField(default=True)
    
    def __str__(self):
        return self.name

class Customer(models.Model):
    name = models.CharField(max_length=150, blank=True, null=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    
    def __str__(self):
        return self.name if self.name else "Walk-in Customer"

class Order(models.Model):
    token_number = models.CharField(max_length=20, unique=True)
    customer = models.ForeignKey(Customer, on_delete=models.SET_NULL, null=True, blank=True)
    date = models.DateTimeField(default=timezone.now)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    final_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    amount_paid = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    payment_status = models.CharField(
        max_length=20, 
        choices=[('Paid', 'Paid'), ('Partial', 'Partial'), ('Unpaid', 'Unpaid')],
        default='Unpaid'
    )
    
    @property
    def balance_due(self):
        return self.final_amount - self.amount_paid

    @property
    def product_names(self):
        return ", ".join([item.variant.product.name for item in self.items.all()])

    def __str__(self):
        return self.token_number

class OrderItem(models.Model):
    STATUS_CHOICES = [
        ('Not Applicable', 'Not Applicable'),
        ('Pending', 'Pending'),
        ('Sent To Darzi', 'Sent To Darzi'),
        ('Cutting', 'Cutting'),
        ('Stitching', 'Stitching'),
        ('Ready', 'Ready'),
        ('Delivered', 'Delivered'),
    ]

    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    variant = models.ForeignKey(ProductVariant, on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField(default=1)
    price = models.DecimalField(max_digits=10, decimal_places=2)  # Price at the time of order
    needs_stitching = models.BooleanField(default=False)
    stitching_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    darzi = models.ForeignKey(Darzi, on_delete=models.SET_NULL, null=True, blank=True)
    stitching_status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Not Applicable')
    delivery_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.order.token_number} - {self.variant.product.name}"    @property
    def total_price(self):
        return (self.price * self.quantity) + self.stitching_price

class Expense(models.Model):
    CATEGORY_CHOICES = [
        ('Utilities', 'Utilities'),
        ('Salaries', 'Salaries'),
        ('Supplies', 'Supplies'),
        ('Rent', 'Rent'),
        ('Marketing', 'Marketing'),
        ('Maintenance', 'Maintenance'),
        ('Other', 'Other'),
    ]
    title = models.CharField(max_length=200)
    amount = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(0)])
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='Other')
    date = models.DateField(default=timezone.now)
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} - {self.amount}"
