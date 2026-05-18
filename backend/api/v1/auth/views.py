from django.contrib.auth import login as session_login, logout as session_logout
from rest_framework import permissions, response, status, views
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .serializers import UserSerializer


class LoginView(TokenObtainPairView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request, *args, **kwargs):
        api_response = super().post(request, *args, **kwargs)
        if api_response.status_code == status.HTTP_200_OK:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            session_login(request, serializer.user)
            api_response.data['user'] = UserSerializer(serializer.user).data
        return api_response


class RefreshView(TokenRefreshView):
    permission_classes = (permissions.AllowAny,)


class CurrentUserView(views.APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        return response.Response(UserSerializer(request.user).data)


class LogoutView(views.APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        refresh = request.data.get('refresh')
        if refresh:
            token = RefreshToken(refresh)
            token.blacklist()
        session_logout(request)
        return response.Response(status=status.HTTP_204_NO_CONTENT)
