from rest_framework import serializers

from dashboard.models import Category, Product, ProductVariant, SubCategory


class SubCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SubCategory
        fields = ('id', 'category', 'name', 'description')


class CategorySerializer(serializers.ModelSerializer):
    subcategories = SubCategorySerializer(many=True, read_only=True)

    class Meta:
        model = Category
        fields = ('id', 'name', 'description', 'subcategories')


class ProductVariantSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    image_url = serializers.SerializerMethodField()
    barcode = serializers.CharField(source='sku', read_only=True)

    class Meta:
        model = ProductVariant
        fields = (
            'id', 'product', 'product_name', 'sku', 'barcode', 'color', 'size',
            'price', 'cost_price', 'stock', 'image', 'image_url',
        )
        extra_kwargs = {'cost_price': {'write_only': False}}

    def get_image_url(self, obj):
        request = self.context.get('request')
        if not obj.image:
            return None
        return request.build_absolute_uri(obj.image.url) if request else obj.image.url


class ProductSerializer(serializers.ModelSerializer):
    variants = ProductVariantSerializer(many=True, required=False)
    category_name = serializers.CharField(source='category.name', read_only=True)
    subcategory_name = serializers.CharField(source='subcategory.name', read_only=True)
    image_url = serializers.SerializerMethodField()
    total_stock = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = (
            'id', 'name', 'category', 'category_name', 'subcategory',
            'subcategory_name', 'image', 'image_url', 'is_handmade',
            'description', 'created_at', 'total_stock', 'variants',
        )

    def get_image_url(self, obj):
        request = self.context.get('request')
        if not obj.image:
            return None
        return request.build_absolute_uri(obj.image.url) if request else obj.image.url

    def get_total_stock(self, obj):
        return sum(variant.stock for variant in obj.variants.all())

    def create(self, validated_data):
        variants_data = validated_data.pop('variants', [])
        product = Product.objects.create(**validated_data)
        for variant_data in variants_data:
            ProductVariant.objects.create(product=product, **variant_data)
        return product

    def update(self, instance, validated_data):
        validated_data.pop('variants', None)
        return super().update(instance, validated_data)

