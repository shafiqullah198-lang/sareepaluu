from django import forms
from .models import Product, ProductVariant, Category, SubCategory, Darzi, Expense

class ExpenseForm(forms.ModelForm):
    class Meta:
        model = Expense
        fields = ['title', 'amount', 'category', 'date', 'description']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'amount': forms.NumberInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'category': forms.Select(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'date': forms.DateInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20', 'type': 'date'}),
            'description': forms.Textarea(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20', 'rows': 2}),
        }

class DarziForm(forms.ModelForm):
    class Meta:
        model = Darzi
        fields = ['name', 'phone', 'active']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'phone': forms.TextInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'active': forms.CheckboxInput(attrs={'class': 'rounded text-premium-gold focus:ring-premium-gold/20'}),
        }

class CategoryForm(forms.ModelForm):
    class Meta:
        model = Category
        fields = ['name', 'description']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'description': forms.Textarea(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20', 'rows': 3}),
        }

class SubCategoryForm(forms.ModelForm):
    class Meta:
        model = SubCategory
        fields = ['category', 'name', 'description']
        widgets = {
            'category': forms.Select(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'name': forms.TextInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'description': forms.Textarea(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20', 'rows': 3}),
        }

class ProductForm(forms.ModelForm):
    category_name = forms.CharField(required=False, widget=forms.TextInput(attrs={
        'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20',
        'list': 'category_list_data',
        'placeholder': 'Select or type new category...'
    }))
    subcategory_name = forms.CharField(required=False, widget=forms.TextInput(attrs={
        'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20',
        'list': 'subcategory_list_data',
        'placeholder': 'Select or type new subcategory...'
    }))
    
    price = forms.DecimalField(required=False, initial=0, widget=forms.NumberInput(attrs={
        'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20',
        'placeholder': 'Default selling price'
    }))
    stock = forms.IntegerField(required=False, initial=0, widget=forms.NumberInput(attrs={
        'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20',
        'placeholder': 'Initial stock quantity'
    }))

    class Meta:
        model = Product
        fields = ['name', 'image', 'is_handmade', 'description']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'image': forms.ClearableFileInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'description': forms.Textarea(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20', 'rows': 3}),
        }

class VariantForm(forms.ModelForm):
    class Meta:
        model = ProductVariant
        fields = ['sku', 'color', 'size', 'price', 'stock', 'image']
        widgets = {
            'sku': forms.TextInput(attrs={
                'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20',
                'placeholder': 'e.g. SR-RED-MED (Unique ID)'
            }),
            'color': forms.TextInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'size': forms.TextInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'price': forms.NumberInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'stock': forms.NumberInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
            'image': forms.ClearableFileInput(attrs={'class': 'glass-input w-full px-4 py-2 text-sm text-slate-700 focus:ring-premium-gold/20'}),
        }
