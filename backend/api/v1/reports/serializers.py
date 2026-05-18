from rest_framework import serializers
from dashboard.models import Expense

class ExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Expense
        fields = ('id', 'amount', 'category', 'date', 'note')
        read_only_fields = ('date',)
