from rest_framework import decorators, permissions, response, status, viewsets

from backend.api.permissions.classes import IsStaffOrReadOnly
from backend.api.v1.mixins import OptimizedQuerysetMixin
from dashboard.models import Category, Product, ProductVariant, SubCategory

from .serializers import CategorySerializer, ProductSerializer, ProductVariantSerializer, SubCategorySerializer


class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.prefetch_related('subcategories').order_by('name')
    serializer_class = CategorySerializer
    permission_classes = (IsStaffOrReadOnly,)
    search_fields = ('name',)
    ordering_fields = ('name', 'id')


class SubCategoryViewSet(viewsets.ModelViewSet):
    queryset = SubCategory.objects.select_related('category').order_by('name')
    serializer_class = SubCategorySerializer
    permission_classes = (IsStaffOrReadOnly,)
    search_fields = ('name', 'category__name')


class ProductViewSet(OptimizedQuerysetMixin, viewsets.ModelViewSet):
    queryset = Product.objects.all().order_by('-created_at')
    serializer_class = ProductSerializer
    permission_classes = (IsStaffOrReadOnly,)
    select_related_fields = ('category', 'subcategory')
    prefetch_related_fields = ('variants',)
    search_fields = ('name', 'description', 'variants__sku', 'variants__color')
    ordering_fields = ('name', 'created_at', 'id')

    @decorators.action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def stock(self, request):
        variants = ProductVariant.objects.select_related('product').order_by('product__name')
        serializer = ProductVariantSerializer(variants, many=True, context={'request': request})
        return response.Response(serializer.data)

    @decorators.action(detail=False, methods=['get'], url_path='barcode/(?P<sku>[^/.]+)')
    def barcode(self, request, sku=None):
        variant = ProductVariant.objects.select_related('product').filter(sku=sku).first()
        if not variant:
            return response.Response({'detail': 'Barcode/SKU not found.'}, status=status.HTTP_404_NOT_FOUND)
        return response.Response(ProductVariantSerializer(variant, context={'request': request}).data)


class ProductVariantViewSet(viewsets.ModelViewSet):
    queryset = ProductVariant.objects.select_related('product').order_by('product__name', 'color')
    serializer_class = ProductVariantSerializer
    permission_classes = (IsStaffOrReadOnly,)
    search_fields = ('sku', 'product__name', 'color', 'size')
    ordering_fields = ('stock', 'price', 'sku')

