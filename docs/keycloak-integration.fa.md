<div dir="rtl">

# یکپارچه‌سازی Gravitee APIM با یک Keycloak موجود

این دستورالعمل برای ادمین Keycloak است که از قبل یک نمونه Keycloak (و یک Realm) را در محیط Production اجرا می‌کند و می‌خواهد Gravitee API Management را به‌عنوان یک کلاینت OIDC جدید به آن اضافه کند. این مراحل همان پیکربندی Realm با نام `gio` را که در فایل `docker/quick-setup/keycloak/realm/realm-gio.json` وجود دارد، روی Realm فعلی شما بازسازی می‌کند — نیازی به Import کردن آن فایل JSON **نیست**.

## ۱. انتخاب Realm

از هر Realm موجودی می‌توانید استفاده کنید (مثلاً `gio`، `corp` و غیره). نام آن را یادداشت کنید؛ آدرس‌های Endpoint سمت Gravitee با الگوی `/realms/<REALM>/...` ساخته می‌شوند.

## ۲. ساخت کلاینت برای کنسول مدیریتی Gravitee

<div dir="ltr">

| Setting | Value |
|---|---|
| Client ID | `gravitee-client` (هر مقداری، اما باید با تنظیمات Gravitee یکی باشد) |
| Protocol | OpenID Connect |
| Client authentication | **On** (confidential) |
| Standard flow | Enabled (Authorization Code) |
| Direct access grants | Enabled (اختیاری) |
| Service accounts roles | Enabled |
| Valid redirect URIs | `https://<console-host>/*` (در حالت dev: `http://localhost:8084/*`) |
| Valid post-logout redirect URIs | `https://<console-host>/*` |
| Web origins | `https://<console-host>` (در حالت dev: `http://localhost:8084`)، یا `+` |
| Root URL / Home URL | `https://<console-host>` |

</div>

پس از ذخیره، وارد تب **Credentials** شوید و **Client secret** را کپی کنید — Gravitee به آن نیاز دارد. در Realm نمونهٔ Dev مقدار آن `00dc0118-2a0d-4249-86a3-3e133f5de145` است؛ برای محیط Production حتماً یک Secret تازه تولید کنید.

## ۳. (اختیاری) کلاینت پورتال توسعه‌دهنده

اگر می‌خواهید SSO روی Developer Portal هم فعال شود، یک کلاینت دوم با همان تنظیمات بسازید، فقط Redirect URI و Web Origins آن باید به آدرس پورتال اشاره کند (در حالت dev: `http://localhost:8085`).

## ۴. Client Scopes

اسکوپ‌های پیش‌فرض `openid`، `profile` و `email` کافی هستند. Gravitee مقادیر `openid` و `profile` را درخواست می‌کند. برای یکپارچه‌سازی پایه نیازی به Mapper سفارشی نیست؛ Claimهای استاندارد `sub`، `email`، `family_name`، `given_name` و `picture` همان چیزی هستند که Gravitee روی کاربر Map می‌کند.

## ۵. نقش‌ها و کاربران

- نقش‌های Realm یا Client که می‌خواهید در Gravitee استفاده شوند را می‌توانید بدون تغییر باقی بگذارید. در پیکربندی Gravitee مقدار `syncMappings=false` تنظیم شده است، یعنی نگاشت خودکار نقش انجام نمی‌شود — مدیریت نقش‌ها داخل خود Gravitee انجام می‌شود مگر اینکه بعداً نگاشت را فعال کنید.
- کاربرانی که از قبل در Realm وجود دارند، پس از تأیید در اولین ورود می‌توانند به Gravitee لاگین کنند.

## ۶. مقادیری که باید به تیم Gravitee تحویل دهید

<div dir="ltr">

```
ISSUER_BASE   = https://<keycloak-host>/realms/<REALM>
CLIENT_ID     = gravitee-client
CLIENT_SECRET = <مقدار کپی‌شده از مرحله ۲>
```

</div>

سپس Management API گرویتی با متغیرهای محیطی یا فایل `gravitee.yml` به این صورت پیکربندی می‌شود:

<div dir="ltr">

```yaml
security:
  providers:
    - type: oidc
      id: keycloak
      clientId: ${CLIENT_ID}
      clientSecret: ${CLIENT_SECRET}
      tokenEndpoint:                 ${ISSUER_BASE}/protocol/openid-connect/token
      tokenIntrospectionEndpoint:    ${ISSUER_BASE}/protocol/openid-connect/token/introspect
      authorizeEndpoint:             ${ISSUER_BASE}/protocol/openid-connect/auth
      userInfoEndpoint:              ${ISSUER_BASE}/protocol/openid-connect/userinfo
      userLogoutEndpoint:            ${ISSUER_BASE}/protocol/openid-connect/logout
      scopes: [ openid, profile ]
      syncMappings: false
      userMapping:
        id: sub
        email: email
        lastname: lastname
        firstname: family_name
        picture: picture
```

</div>

شکل معادل آن به صورت متغیر محیطی در فایل `docker/quick-setup/keycloak/docker-compose.yml` (خطوط ۱۵۵ تا ۱۷۲) با پیشوند `gravitee_security_providers_2_*` موجود است.

## ۷. ملاحظات Production

- **TLS:** در محیط Production باید Keycloak روی HTTPS ارائه شود. مقدار `KC_HOSTNAME` را تنظیم کنید و به‌جای `start-dev` از دستور `start` با تنظیمات صحیح Hostname و Proxy استفاده کنید.
- **دسترسی شبکه:** کانتینر Management API باید بتواند Hostname مربوط به Keycloak (که در Endpointها قرار داده‌اید) را Resolve کند. در محیط Dev از `auth.localhost` پشت یک Nginx و کلید `links:` استفاده شده، اما در Production کافی است نام DNS عمومی Keycloak را بگذارید.
- **چرخش Secret:** Secret کلاینت `gravitee-client` را به‌صورت زمان‌بندی‌شده Rotate کنید و مقدار جدید را در محل ذخیرهٔ Secret یا متغیرهای محیطی Gravitee به‌روزرسانی کنید.
- **Redirect URIs:** آن‌ها را سخت‌گیرانه نگه دارید — بدون Wildcard روی Host و فقط در سطح Path — و فقط آدرس‌های واقعی Console و Portal را اضافه کنید.

این تمام کاری است که باید سمت Keycloak انجام شود: برای هر UI گرویتی یک Confidential Client، به‌علاوهٔ آدرس Issuer و Client Secret که به تیم اجراکنندهٔ Gravitee تحویل داده می‌شود.

</div>
