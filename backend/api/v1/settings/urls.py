from django.urls import path

from .views import CompanyProfileView, TaxSettingsView

urlpatterns = [
    path('company/', CompanyProfileView.as_view(), name='api-company-profile'),
    path('tax/', TaxSettingsView.as_view(), name='api-tax-settings'),
]

