from django.urls import include, path

urlpatterns = [
    path('auth/', include('backend.api.v1.auth.urls')),
    path('products/', include('backend.api.v1.products.urls')),
    path('customers/', include('backend.api.v1.customers.urls')),
    path('orders/', include('backend.api.v1.orders.urls')),
    path('pos/', include('backend.api.v1.pos.urls')),
    path('reports/', include('backend.api.v1.reports.urls')),
    path('settings/', include('backend.api.v1.settings.urls')),
]
