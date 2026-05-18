from django.urls import path

from .views import CartView, CheckoutView

urlpatterns = [
    path('cart/', CartView.as_view(), name='api-pos-cart'),
    path('checkout/', CheckoutView.as_view(), name='api-pos-checkout'),
]

