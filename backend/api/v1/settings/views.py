from rest_framework import permissions, response, views


class CompanyProfileView(views.APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        return response.Response({
            'name': 'Saree by Pallu',
            'currency': 'PKR',
            'invoice_prefix': 'INV',
            'phone': '',
            'address': '',
        })


class TaxSettingsView(views.APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        return response.Response({
            'tax_enabled': False,
            'default_tax_rate': 0,
            'prices_include_tax': True,
        })

