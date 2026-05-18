"""
Django settings for config project.
"""

import sys
import os
from pathlib import Path
from datetime import timedelta

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Determine if we are running as a compiled EXE
IS_FROZEN = getattr(sys, 'frozen', False)
if IS_FROZEN:
    # Path to the actual executable folder (for persistent data)
    EXE_DIR = Path(sys.executable).parent
else:
    EXE_DIR = BASE_DIR

# ---------------------------------------------------------------------------
# Load .env file automatically when NOT frozen (development mode)
# ---------------------------------------------------------------------------
if not IS_FROZEN:
    _env_file = BASE_DIR / '.env'
    if _env_file.exists():
        with open(_env_file, encoding='utf-8') as _f:
            for _line in _f:
                _line = _line.strip()
                if _line and not _line.startswith('#') and '=' in _line:
                    _key, _val = _line.split('=', 1)
                    os.environ.setdefault(_key.strip(), _val.strip())

# ---------------------------------------------------------------------------
# Core security settings (all env-driven so devs never touch this file)
# ---------------------------------------------------------------------------

SECRET_KEY = os.getenv(
    'DJANGO_SECRET_KEY',
    'django-insecure-2f#csh)a6m0&o(q7wy4^n!ji#8vj)gpl)uxj2=wn$l4wosu6q5'
)

# SECURITY WARNING: never run DEBUG=True in production!
DEBUG = os.getenv('DJANGO_DEBUG', 'False').lower() in ('true', '1', 'yes')

# ---------------------------------------------------------------------------
# Hosts & CORS
# ---------------------------------------------------------------------------

ALLOWED_HOSTS = [
    h.strip()
    for h in os.getenv(
        'DJANGO_ALLOWED_HOSTS',
        '*, localhost, 127.0.0.1, 0.0.0.0, 10.0.2.2, 192.168.18.51'
    ).split(',')
    if h.strip()
]

# Always include wildcard in DEBUG mode so developers never hit a 400
if DEBUG and '*' not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append('*')

# --- CORS ---
# In DEBUG mode allow everything for convenience; in production restrict to
# the list built from the env variable.
CORS_ALLOW_ALL_ORIGINS = DEBUG or (os.getenv('CORS_ALLOW_ALL_ORIGINS', 'False').lower() in ('true', '1', 'yes'))

# Always-allowed development origins (merged with any env extras)
_dev_origins = [
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'http://localhost:54321',   # Flutter web default port
    'http://127.0.0.1:54321',
    'http://10.0.2.2:8000',    # Android emulator → host machine
    'http://10.0.2.2:3000',
    'http://192.168.18.51:8000',  # Real Android device → LAN IP
    'http://192.168.18.51:3000',
]

_env_origins = [
    o.strip()
    for o in os.getenv('CORS_ALLOWED_ORIGINS', '').split(',')
    if o.strip()
]

# Add configurable LAN IP for physical device testing
_local_ip = os.getenv('LOCAL_DEV_IP', '').strip()
if _local_ip:
    _dev_origins.append(f'http://{_local_ip}:8000')
    _dev_origins.append(f'http://{_local_ip}:3000')

CORS_ALLOWED_ORIGINS = list(dict.fromkeys(_dev_origins + _env_origins))  # deduplicated

CORS_ALLOW_CREDENTIALS = True  # Required for session/cookie auth across origins

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'x-api-version',
]

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

# --- CSRF trusted origins (required for POST/PUT/DELETE from Flutter/web) ---
_csrf_env = [
    o.strip()
    for o in os.getenv('CSRF_TRUSTED_ORIGINS', '').split(',')
    if o.strip()
]

_csrf_defaults = [
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'http://10.0.2.2:8000',
    'http://192.168.18.51:8000',  # Real Android device → LAN IP
]
if _local_ip:
    _csrf_defaults.append(f'http://{_local_ip}:8000')

CSRF_TRUSTED_ORIGINS = list(dict.fromkeys(_csrf_defaults + _csrf_env))

# ---------------------------------------------------------------------------
# Application definition
# ---------------------------------------------------------------------------

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'corsheaders',
    'rest_framework',
    'rest_framework_simplejwt.token_blacklist',
    'dashboard',
    'backend.api',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'corsheaders.middleware.CorsMiddleware',   # Must be before CommonMiddleware
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'backend.api.middleware.DashboardLoginRequiredMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'sareepaluu_db',
        'USER': 'postgres',
        'PASSWORD': 'khan123',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# ---------------------------------------------------------------------------
# Password validation
# ---------------------------------------------------------------------------

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# ---------------------------------------------------------------------------
# Internationalisation
# ---------------------------------------------------------------------------

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# ---------------------------------------------------------------------------
# Static & media files
# ---------------------------------------------------------------------------

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

STATICFILES_DIRS = [
    BASE_DIR / 'static',
]

STATICFILES_STORAGE = 'whitenoise.storage.CompressedStaticFilesStorage'

MEDIA_URL = '/media/'
MEDIA_ROOT = EXE_DIR / 'media'

# ---------------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------------

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
LOGIN_URL = '/login/'
LOGIN_REDIRECT_URL = '/'
LOGOUT_REDIRECT_URL = '/login/'

# ---------------------------------------------------------------------------
# Django REST Framework
# ---------------------------------------------------------------------------

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'backend.api.pagination.classes.StandardResultsSetPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_FILTER_BACKENDS': (
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ),
    'EXCEPTION_HANDLER': 'backend.api.v1.exceptions.api_exception_handler',
}

# ---------------------------------------------------------------------------
# SimpleJWT
# ---------------------------------------------------------------------------

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=int(os.getenv('JWT_ACCESS_MINUTES', '60'))),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=int(os.getenv('JWT_REFRESH_DAYS', '7'))),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
}
