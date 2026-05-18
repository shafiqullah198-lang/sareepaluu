from rest_framework import permissions, response, status, views

from backend.api.v1.orders.serializers import OrderSerializer
from backend.api.v1.products.serializers import CategorySerializer, ProductSerializer
from backend.api.v1.services import create_order_from_checkout
from dashboard.models import Category, Product

from .serializers import CheckoutSerializer


class CartView(views.APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        products = Product.objects.select_related('category', 'subcategory').prefetch_related('variants')
        categories = Category.objects.prefetch_related('subcategories')
        return response.Response({
            'categories': CategorySerializer(categories, many=True, context={'request': request}).data,
            'products': ProductSerializer(products, many=True, context={'request': request}).data,
        })


class CheckoutView(views.APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        if not request.user.is_staff:
            return response.Response({'detail': 'Staff access required.'}, status=status.HTTP_403_FORBIDDEN)
        serializer = CheckoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = create_order_from_checkout(serializer.validated_data)
        return response.Response(OrderSerializer(order, context={'request': request}).data, status=status.HTTP_201_CREATED)
