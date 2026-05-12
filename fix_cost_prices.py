#!/usr/bin/env python
"""
Migration script to populate cost_price from price field for all variants
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from dashboard.models import ProductVariant

# Update all variants where cost_price is 0 and price is set
updated_count = 0
variants = ProductVariant.objects.filter(cost_price=0, price__gt=0)

for variant in variants:
    variant.cost_price = variant.price
    variant.save()
    updated_count += 1

print(f"Updated {updated_count} variants")
print(f"Total variants: {ProductVariant.objects.count()}")
print(f"Variants with cost_price > 0: {ProductVariant.objects.filter(cost_price__gt=0).count()}")
