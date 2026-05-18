from rest_framework.routers import DefaultRouter

from .views import CategoryViewSet, ProductVariantViewSet, ProductViewSet, SubCategoryViewSet

router = DefaultRouter()
router.register('categories', CategoryViewSet, basename='category')
router.register('subcategories', SubCategoryViewSet, basename='subcategory')
router.register('variants', ProductVariantViewSet, basename='variant')
router.register('', ProductViewSet, basename='product')

urlpatterns = router.urls

