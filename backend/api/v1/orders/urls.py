from django.urls import include, path
from rest_framework import routers

from .views import DarziViewSet, OrderItemViewSet, OrderViewSet

router = routers.DefaultRouter()
router.register(r'items', OrderItemViewSet)
router.register(r'darzis', DarziViewSet)
router.register(r'', OrderViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
