from django.urls import include, path
from rest_framework import routers

from .views import AnalyticsSummaryView, ExpenseViewSet, SalesReportView

router = routers.DefaultRouter()
router.register(r'expenses', ExpenseViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('sales/', SalesReportView.as_view(), name='api-sales-report'),
    path('summary/', AnalyticsSummaryView.as_view(), name='api-analytics-summary'),
]
