from django.conf import settings
from django.shortcuts import redirect


class DashboardLoginRequiredMiddleware:
    """Protect the HTML dashboard while leaving API/admin/static routes to their own auth."""

    EXEMPT_PREFIXES = (
        '/api/',
        '/admin/',
        '/login/',
        '/logout/',
        '/static/',
        '/media/',
    )

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if (
            not request.user.is_authenticated
            and not request.path.startswith(self.EXEMPT_PREFIXES)
        ):
            return redirect(f"{settings.LOGIN_URL}?next={request.get_full_path()}")
        return self.get_response(request)

