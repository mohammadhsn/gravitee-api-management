<div dir="rtl">

# راهنمای راه‌اندازی Nginx برای Gravitee APIM (محیط Production)

این راهنما برای ادمین سیستم نوشته شده است تا Gravitee API Management را که از قبل با `docker-compose` روی یک VM پروداکشن در حال اجرا است، پشت Nginx همراه با TLS قرار دهد.

فایل همراه `gravitee.conf` در همین پوشه، همان کانفیگ Server-Block در Nginx است که در مراحل زیر مستقر می‌شود.

## نتیجهٔ نهایی

سه Endpoint عمومی روی HTTPS، که همگی توسط یک نمونهٔ Nginx روی همان VM سرو می‌شوند:

<div dir="ltr">

| Domain | Purpose | Backend (localhost) |
|---|---|---|
| `gateway.example.com` | Gateway — runtime API traffic | `127.0.0.1:8082` |
| `console.example.com` | Admin Console SPA + Management REST (`/management`) | `127.0.0.1:8084` + `127.0.0.1:8083` |
| `portal.example.com` | Developer Portal SPA + Portal REST (`/portal`) | `127.0.0.1:8085` + `127.0.0.1:8083` |

</div>

## پیش‌نیازها

- یک VM لینوکسی با Docker و docker-compose که استک Gravitee را از روی فایل `docker/quick-setup/keycloak/docker-compose.yml` (یا نسخهٔ شخصی‌سازی‌شدهٔ خودتان) اجرا می‌کند.
- دسترسی `sudo` روی VM.
- سه رکورد DNS از نوع A/AAAA که دامنه‌های انتخابی را به IP عمومی VM اشاره دهند.
- باز بودن پورت‌های `80` و `443` در Firewall یا Security Group ماشین.

## ۱. نصب Nginx و Certbot

برای Ubuntu / Debian:

<div dir="ltr">

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

</div>

برای RHEL / Rocky / Alma:

<div dir="ltr">

```bash
sudo dnf install -y nginx certbot python3-certbot-nginx
sudo systemctl enable --now nginx
```

</div>

قبل از ادامه، مطمئن شوید Nginx صفحهٔ پیش‌فرض را روی پورت ۸۰ سرو می‌کند:

<div dir="ltr">

```bash
curl -I http://<vm-public-ip>/
```

</div>

## ۲. محدود کردن پورت‌های Docker به Localhost

به‌صورت پیش‌فرض compose پورت‌ها را روی `0.0.0.0:8083`، `0.0.0.0:8084` و `0.0.0.0:8085` Bind می‌کند که یعنی Backendها به‌طور مستقیم در دسترس Public هستند. فایل `docker-compose.yml` را به این صورت ویرایش کنید تا فقط Nginx (که روی Host اجرا می‌شود) بتواند به آن‌ها دسترسی داشته باشد:

<div dir="ltr">

```yaml
  management_api:
    ports:
      - "127.0.0.1:8083:8083"

  management_ui:
    ports:
      - "127.0.0.1:8084:8080"

  portal_ui:
    ports:
      - "127.0.0.1:8085:8080"

  gateway:
    ports:
      - "127.0.0.1:8082:8082"   # تنها در صورتی روی 0.0.0.0 بگذارید که Nginx روی هاست دیگری باشد
```

</div>

## ۳. اعلام آدرس Public به SPAها

Image مربوط به Console و Portal، آدرس API را در زمان استارت کانتینر داخل SPA Bake می‌کند. متغیرهای محیطی را به‌صورت زیر روی URL عمومی HTTPS تنظیم کنید:

<div dir="ltr">

```yaml
  management_ui:
    environment:
      - MGMT_API_URL=https://console.example.com/management/

  portal_ui:
    environment:
      - PORTAL_API_URL=https://portal.example.com/portal
```

</div>

سپس کانتینرها را از نو بسازید تا مقادیر جدید اعمال شوند:

<div dir="ltr">

```bash
docker compose up -d --force-recreate management_ui portal_ui
```

</div>

## ۴. قرار دادن کانفیگ Nginx

فایل `gravitee.conf` را در مسیر Drop-in مربوط به Nginx کپی کنید و `example.com` را با دامنهٔ واقعی خودتان جایگزین کنید:

<div dir="ltr">

```bash
sudo cp gravitee.conf /etc/nginx/conf.d/gravitee.conf
sudo sed -i 's/example\.com/yourdomain.tld/g' /etc/nginx/conf.d/gravitee.conf
```

</div>

اگر در فایل اصلی `nginx.conf` از قبل دایرکتیوهای `proxy_set_header`، `proxy_http_version` یا بلاک `map $http_upgrade ...` در سطح `http {}` تعریف شده‌اند، **همان خطوط را از ابتدای `gravitee.conf` حذف کنید** تا با خطای دایرکتیو تکراری مواجه نشوید. تمیزترین راه‌حل این است که این Defaultهای مشترک را به فایل جداگانه‌ای مثل `/etc/nginx/conf.d/00-defaults.conf` منتقل کنید.

اعتبار کانفیگ را بررسی کنید (تا قبل از صدور Certificate طبیعی است که خطا بدهد، در مرحلهٔ بعد رفع می‌شود):

<div dir="ltr">

```bash
sudo nginx -t
```

</div>

## ۵. صدور گواهی TLS

با استفاده از پلاگین Nginx در Certbot، گواهی هر سه دامنه را همزمان صادر و نصب کنید:

<div dir="ltr">

```bash
sudo certbot --nginx \
  -d gateway.example.com \
  -d console.example.com \
  -d portal.example.com
```

</div>

اگر می‌خواهید مسیرهای موجود در `gravitee.conf` دقیقاً به همان شکل باقی بماند، از حالت `certonly` استفاده کنید تا فقط فایل‌های گواهی صادر شوند و Nginx آن‌ها را از مسیر استاندارد بردارد:

<div dir="ltr">

```bash
sudo certbot certonly --nginx \
  -d gateway.example.com \
  -d console.example.com \
  -d portal.example.com
```

</div>

Certbot یک Timer در systemd نصب می‌کند که تمدید را خودکار انجام می‌دهد. صحت آن را بررسی کنید:

<div dir="ltr">

```bash
systemctl list-timers | grep certbot
sudo certbot renew --dry-run
```

</div>

## ۶. Reload کردن Nginx

<div dir="ltr">

```bash
sudo nginx -t && sudo systemctl reload nginx
```

</div>

حالا `https://console.example.com` را در مرورگر باز کنید — باید صفحهٔ ورود کنسول Gravitee را ببینید. همین موضوع برای `https://portal.example.com` نیز صادق است.

## ۷. (در صورت استفاده از Keycloak) به‌روزرسانی Redirect URIها

اگر مطابق بخش Keycloak در [`../fa-gravitee-howto-guide.md`](../fa-gravitee-howto-guide.md) پیش رفته‌اید، در کلاینت `gravitee-client` کیلوک این مقادیر را به‌روزرسانی کنید:

- **Valid Redirect URIs:** `https://console.example.com/*`, `https://portal.example.com/*`
- **Web Origins:** `https://console.example.com`, `https://portal.example.com`

و در متغیرهای محیطی OIDC مربوط به Management API، آدرس Issuer را به‌جای `http://auth.localhost/...` به آدرس عمومی Keycloak تغییر دهید (مثلاً `https://auth.example.com/realms/<REALM>/...`).

## عیب‌یابی

<div dir="ltr">

| Symptom | Likely cause |
|---|---|
| `502 Bad Gateway` on `/` | UI container is down, or port is not bound on `127.0.0.1`. Check `docker ps`. |
| SPA loads but API calls fail with CORS or `401` | `MGMT_API_URL` / `PORTAL_API_URL` is not updated, or Nginx is not proxying `/management` / `/portal`. |
| Login keeps redirecting back to login | Keycloak redirect URIs / web origins still point at `localhost`. Update them. |
| Client IP appears as `127.0.0.1` in logs | Add `set_real_ip_from <trusted-proxy>` and `real_ip_header X-Forwarded-For` if you sit behind another proxy / CDN. |
| Streaming endpoints (SSE / chunked) are buffered | `proxy_buffering off` must be in scope; check it is not overridden inside a `location {}`. |

</div>

## چک‌لیست Hardening

- بعد از اطمینان از پایداری TLS، HSTS را اضافه کنید: داخل هر بلاک HTTPS `server {}` خط زیر را قرار دهید.

  <div dir="ltr">

  ```nginx
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
  ```

  </div>

- یک `Content-Security-Policy` مناسب برای Hostهای Console و Portal تعریف کنید.
- اگر Gateway فقط داخلی است، با IP Allowlist دسترسی به دامنهٔ آن را محدود کنید.
- لاگ‌های Access مربوط به Nginx را به Log Shipper بفرستید؛ لاگ‌های Management API از قبل در `./.logs/apim-management-api` ذخیره می‌شوند.
- با وجود اجرای خودکار Timer، تست `certbot renew` را در چک‌لیست ماهانهٔ نگهداری قرار دهید.

</div>
