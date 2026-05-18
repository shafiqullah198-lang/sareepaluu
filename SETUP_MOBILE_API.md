# SareePaluu — Mobile & API Setup Guide

> Complete guide to run Django + Flutter together for local development, emulator testing, and physical device testing.

---

## 1. Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Python | ≥ 3.10 | `python --version` |
| pip | latest | `pip --version` |
| Flutter SDK | ≥ 3.4 | `flutter --version` |
| Android Studio | latest (for emulator) | — |
| Chrome | any | for web testing |

---

## 2. Django Backend Setup

### 2a. Install dependencies

```bash
cd sareepaluu
pip install -r requirements.txt
```

### 2b. Create your `.env` file

```bash
# Windows
copy .env.example .env

# macOS / Linux
cp .env.example .env
```

Open `.env` and set at minimum:

```env
DJANGO_DEBUG=True
DJANGO_SECRET_KEY=any-long-random-string
LOCAL_DEV_IP=          # leave blank unless testing on a physical device
```

### 2c. Run database migrations

```bash
python manage.py migrate
```

### 2d. Start the development server

> **Critical:** Use `0.0.0.0:8000` — this binds to ALL network interfaces,
> which is required for Android emulators and physical devices to connect.

```bash
python manage.py runserver 0.0.0.0:8000
```

You should see:
```
Django version 5.x, using settings 'config.settings'
Starting development server at http://0.0.0.0:8000/
```

### 2e. Verify the API is reachable

```bash
# Should return HTTP 401 (not 500 or connection refused)
curl http://127.0.0.1:8000/api/v1/auth/me/
```

Expected response:
```json
{"success": false, "message": "Authentication credentials were not provided.", ...}
```

---

## 3. Flutter App Setup

```bash
cd mobile_app
flutter pub get
```

---

## 4. Running Flutter — By Platform

### 4a. Chrome / Web

No special configuration needed.

```bash
flutter run -d chrome
```

The app auto-connects to `http://localhost:8000/api/v1`.

---

### 4b. Android Emulator

The Android emulator uses a virtual network where the **host machine**
is reachable at `10.0.2.2` (not `127.0.0.1`).

The app auto-detects this — no configuration needed.

```bash
# Start an emulator first (Android Studio AVD Manager or CLI)
flutter emulators --launch <emulator_id>

# Then run
flutter run -d emulator-5554
```

The app connects to `http://10.0.2.2:8000/api/v1` automatically.

**Verify from inside the emulator:**
Open the emulator's browser and go to `http://10.0.2.2:8000/api/v1/auth/me/`.
You should see the 401 JSON response.

---

### 4c. iOS Simulator

```bash
flutter run -d "iPhone 15"
```

The app auto-connects to `http://localhost:8000/api/v1`.

---

### 4d. Physical Android/iOS Device (WiFi)

**Step 1 — Find your machine's LAN IP:**

```bash
# Windows
ipconfig
# Look for "IPv4 Address" under your WiFi adapter, e.g. 192.168.1.55

# macOS
ifconfig en0 | grep inet

# Linux
ip addr show
```

**Step 2 — Update `.env` on the Django server:**

```env
LOCAL_DEV_IP=192.168.1.55
```

Restart Django (`python manage.py runserver 0.0.0.0:8000`).

**Step 3 — Run Flutter with your LAN IP:**

```bash
flutter run --dart-define=LOCAL_IP=192.168.1.55
```

The app will connect to `http://192.168.1.55:8000/api/v1`.

> **Firewall note:** On Windows, allow port 8000 through Windows Defender Firewall,
> or temporarily disable the firewall for your private network.

---

## 5. API Endpoints Reference

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/v1/auth/login/` | POST | Public | Get JWT tokens |
| `/api/v1/auth/refresh/` | POST | Public | Refresh access token |
| `/api/v1/auth/logout/` | POST | Public | Blacklist refresh token |
| `/api/v1/auth/me/` | GET | JWT | Get current user |
| `/api/v1/products/` | GET | JWT | List products |
| `/api/v1/orders/` | GET | JWT | List orders |
| `/api/v1/customers/` | GET | JWT | List customers |
| `/api/v1/pos/checkout/` | POST | JWT | Create POS order |
| `/api/v1/reports/summary/` | GET | JWT | Dashboard stats |

---

## 6. Common Errors & Fixes

### ❌ `Connection refused` / `SocketException`

| Cause | Fix |
|-------|-----|
| Django not running | Run `python manage.py runserver 0.0.0.0:8000` |
| Wrong `runserver` address (used `127.0.0.1:8000`) | Must use `0.0.0.0:8000` |
| Android emulator using `127.0.0.1` | App auto-uses `10.0.2.2` — check `AppConfig.apiBaseUrl` in debug logs |
| Physical device on different WiFi | Both device and PC must be on same network |
| Windows Firewall blocking port 8000 | Allow inbound TCP port 8000 |

---

### ❌ `CORS error` (Chrome / Web)

| Cause | Fix |
|-------|-----|
| `DJANGO_DEBUG=False` in `.env` | Set `DJANGO_DEBUG=True` for dev |
| Origin not in `CORS_ALLOWED_ORIGINS` | In debug mode, all origins allowed automatically |
| `corsheaders` not first in MIDDLEWARE | Already fixed — `CorsMiddleware` is before `CommonMiddleware` |

---

### ❌ `401 Unauthorized` on every request

| Cause | Fix |
|-------|-----|
| Token not sent | Check `Authorization` header in debug logs |
| Access token expired | ApiClient auto-refreshes — if it fails, it redirects to login |
| Refresh token expired | Log in again |
| Wrong base URL (tokens saved for different URL) | Clear app storage and log in fresh |

---

### ❌ `403 Forbidden`

| Cause | Fix |
|-------|-----|
| CSRF rejected | All API views use JWT — CSRF is exempt. Verify `CsrfViewMiddleware` is after `CorsMiddleware` |
| Wrong user permissions | Log in with a staff/superuser account |

---

### ❌ `Timeout` errors

| Cause | Fix |
|-------|-----|
| Django too slow to respond | Check for blocking ORM queries; Django must be running |
| Network congestion | Client has 30s timeout — should be sufficient for local dev |

---

### ❌ Prices / amounts show as `0`

| Cause | Fix |
|-------|-----|
| JSON field returned as string instead of number | `safeDouble()` in `api_helpers.dart` handles string→double conversion |
| Field name mismatch | Check `Order.fromJson` and API response keys |

---

## 7. Debug Checklist

Run through this checklist when something doesn't work:

```
[ ] Django is running on 0.0.0.0:8000 (not 127.0.0.1:8000)
[ ] .env file exists and DJANGO_DEBUG=True
[ ] curl http://127.0.0.1:8000/api/v1/auth/me/ returns 401 (not 500)
[ ] Flutter debug console shows "[ApiClient] Base URL →" line on startup
[ ] Flutter debug console shows "[ApiClient] Platform →" line on startup
[ ] The displayed URL matches the expected platform URL
[ ] For physical device: LOCAL_IP matches the machine's actual LAN IP
[ ] For physical device: Windows Firewall allows port 8000
[ ] For physical device: device and PC on same WiFi network
[ ] Dio LogInterceptor output visible in Flutter debug console (debug mode only)
```

---

## 8. Environment Variables Summary

### Django (`.env` in project root)

| Variable | Default | Description |
|----------|---------|-------------|
| `DJANGO_SECRET_KEY` | insecure default | Django secret key — change in production |
| `DJANGO_DEBUG` | `False` | Set `True` for local dev |
| `DJANGO_ALLOWED_HOSTS` | `*, localhost, 127.0.0.1, 0.0.0.0, 10.0.2.2` | Hosts Django accepts |
| `CORS_ALLOW_ALL_ORIGINS` | `False` | Auto-`True` when `DEBUG=True` |
| `CORS_ALLOWED_ORIGINS` | common dev origins | Extra origins to allow |
| `CSRF_TRUSTED_ORIGINS` | common dev origins | Origins allowed to POST |
| `LOCAL_DEV_IP` | _(empty)_ | Your LAN IP for physical device testing |
| `JWT_ACCESS_MINUTES` | `60` | Access token lifetime |
| `JWT_REFRESH_DAYS` | `7` | Refresh token lifetime |

### Flutter (`--dart-define` flags)

| Variable | Default | Description |
|----------|---------|-------------|
| `API_BASE_URL` | _(auto-detected)_ | Full override for API base URL |
| `LOCAL_IP` | _(empty)_ | LAN IP for physical device testing |

---

## 9. Architecture Notes

```
┌─────────────────────────────────────────────────┐
│               Flutter App                        │
│  AppConfig.apiBaseUrl (platform-aware)           │
│       ↓                                          │
│  ApiClient (Dio + JWT interceptor)               │
│       ↓                                          │
│  Providers (AuthProvider, CatalogProvider, ...)  │
│       ↓                                          │
│  Screens (LoginScreen, POSScreen, ...)           │
└─────────────────────────────────────────────────┘
            HTTP/JSON (port 8000)
┌─────────────────────────────────────────────────┐
│               Django Backend                     │
│  CORS → JWT Auth → DRF Views → SQLite DB         │
│  /api/v1/auth/   products/   orders/   pos/      │
└─────────────────────────────────────────────────┘
```
