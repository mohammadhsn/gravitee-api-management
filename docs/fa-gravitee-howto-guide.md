# راهنمای عملی Gravitee 4.x + Keycloak

> **مخاطبان:** مهندسانی که پلتفرم Gravitee 4.x را به‌صورت self-hosted اجرا می‌کنند.
> **محدوده:** دستورالعمل‌های گام‌به‌گام عملی برای ایجاد، امن‌سازی، انتشار، ممیزی و مستندسازی APIها.
> **نسخه:** 2.0 — شامل بخش‌های جدید Audit Logging & Analysis و ویژگی‌های مستندسازی API.

---

## فهرست مطالب

1. [مفاهیم پایه و اصطلاحات](#۱-مفاهیم-پایه-و-اصطلاحات)
2. [ایجاد و انتشار اولین API](#۲-ایجاد-و-انتشار-اولین-api)
   - 2.1 [ایجاد یک API](#۲۱-ایجاد-یک-api)
   - 2.2 [افزودن امنیت — API Key](#۲۲-افزودن-امنیت--api-key)
   - 2.3 [افزودن امنیت — JWT از طریق Keycloak](#۲۳-افزودن-امنیت--jwt-از-طریق-keycloak)
   - 2.4 [افزودن Policy](#۲۴-افزودن-policy)
   - 2.5 [انتشار API](#۲۵-انتشار-api)
   - 2.6 [افزودن مستندات API](#۲۶-افزودن-مستندات-api)
3. [آموزش‌های کاربردی](#۳-آموزش‌های-کاربردی)
   - 3.1 [محدودیت نرخ درخواست برای REST APIها](#۳۱-محدودیت-نرخ-درخواست-برای-rest-apiها)
   - 3.2 [پیکربندی امنیت JWT](#۳۲-پیکربندی-امنیت-jwt)
   - 3.3 [افزودن RBAC به پلن‌های JWT](#۳۳-افزودن-rbac-به-پلن‌های-jwt)
   - 3.4 [پیکربندی Dynamic Client Registration یا DCR](#۳۴-پیکربندی-dynamic-client-registration-یا-dcr)
   - 3.5 [امن‌سازی و انتشار سرویس‌های gRPC](#۳۵-امن‌سازی-و-انتشار-سرویس‌های-grpc)
   - 3.6 [انتشار سرویس‌های SOAP به‌عنوان REST API](#۳۶-انتشار-سرویس‌های-soap-به‌عنوان-rest-api)
   - 3.7 [ایجاد و انتشار API از طریق Management API](#۳۷-ایجاد-و-انتشار-api-از-طریق-management-api)
   - 3.8 [اتصال یک Endpoint با SSE](#۳۸-اتصال-یک-endpoint-با-sse)
4. [بررسی عمیق: جریان شفاف توکن سرویس‌به‌سرویس](#۴-بررسی-عمیق-جریان-شفاف-توکن-سرویس‌به‌سرویس)
5. [ثبت وقایع و تحلیل API](#۵-ثبت-وقایع-و-تحلیل-api)
   - 5.1 [آنچه ثبت می‌شود](#۵۱-آنچه-ثبت-می‌شود)
   - 5.2 [دسترسی به گزارش‌های ممیزی و فیلتر کردن آن‌ها](#۵۲-دسترسی-به-گزارش‌های-ممیزی-و-فیلتر-کردن-آن‌ها)
   - 5.3 [تحلیل در سطح API](#۵۳-تحلیل-در-سطح-api)
   - 5.4 [تحلیل در سطح پلتفرم](#۵۴-تحلیل-در-سطح-پلتفرم)
   - 5.5 [تحلیل فعالیت اشتراک و مصرف‌کننده](#۵۵-تحلیل-فعالیت-اشتراک-و-مصرف‌کننده)
   - 5.6 [خروجی گرفتن از داده‌های ممیزی و تحلیل](#۵۶-خروجی-گرفتن-از-داده‌های-ممیزی-و-تحلیل)
   - 5.7 [ارسال گزارش‌ها به سیستم‌های خارجی](#۵۷-ارسال-گزارش‌ها-به-سیستم‌های-خارجی)
6. [ویژگی‌ها و گزینه‌های مستندسازی](#۶-ویژگی‌ها-و-گزینه‌های-مستندسازی)
   - 6.1 [انواع صفحات مستندات](#۶۱-انواع-صفحات-مستندات)
   - 6.2 [منابع مستندات](#۶۲-منابع-مستندات)
   - 6.3 [سازماندهی مستندات با پوشه‌ها](#۶۳-سازماندهی-مستندات-با-پوشه‌ها)
   - 6.4 [مدیریت دید و دسترسی](#۶۴-مدیریت-دید-و-دسترسی)
   - 6.5 [متادیتا و دسته‌بندی API](#۶۵-متادیتا-و-دسته‌بندی-api)
   - 6.6 [پیوست مستندات به پلن‌ها](#۶۶-پیوست-مستندات-به-پلن‌ها)
   - 6.7 [همگام‌سازی مستندات از Git](#۶۷-همگام‌سازی-مستندات-از-git)
   - 6.8 [مرجع کامل گزینه‌های مستندسازی](#۶۸-مرجع-کامل-گزینه‌های-مستندسازی)

---

## ۱. مفاهیم پایه و اصطلاحات

پیش از کار با Gravitee، با این اصطلاحات آشنا شوید. این مفاهیم در طول داشبورد و این راهنما استفاده می‌شوند.

| اصطلاح | معنی در Gravitee |
|---|---|
| **API** | تعریف منطقی API شما — شامل entrypointها، endpointها، planها و policyها. نمایانگر قرارداد سرویس شما است. |
| **Application** | یک موجودیت سمت مصرف‌کننده (مثلاً یک برنامه فرانت‌اند یا یک microservice) که برای فراخوانی یک API به یک Plan مشترک می‌شود. |
| **Gateway** | پراکسی runtime که تمام policyها (امنیت، rate limiting، تبدیل) را روی هر درخواست ورودی اعمال می‌کند. ترافیک از آن عبور می‌کند — هرگز مستقیماً به backend شما نمی‌رسد. |
| **Proxy** | حالت عملیاتی که در آن Gateway درخواست‌ها را به یک سرویس backend فوروارد می‌کند. این مدل استقرار استاندارد برای REST، SOAP و اغلب HTTP APIهاست. |
| **Entrypoint** | نحوه دسترسی مصرف‌کنندگان به API شما از طریق Gateway. پروتکل و مسیر را تعریف می‌کند (مثلاً `https://gateway.company.com/service-a/v1`). |
| **Endpoint** | سرویس backend که Gateway درخواست‌ها را به آن فوروارد می‌کند (مثلاً `http://service-a.internal:8080`). مستقیماً در دسترس مصرف‌کنندگان نیست. |
| **Plan** | مجموعه‌ای از قوانین دسترسی که به یک API متصل است. نوع امنیت (API Key، JWT، OAuth2، Keyless) و هر گونه quota یا محدودیت را تعریف می‌کند. مصرف‌کنندگان به یک Plan مشترک می‌شوند. |
| **Policy** | یک مرحله پردازشی که روی یک درخواست یا پاسخ اعمال می‌شود (مثلاً افزودن یک header، rate limit، فراخوانی یک سرویس خارجی). Policyها در یک flow زنجیر می‌شوند. |
| **Deployment** | عمل push کردن پیکربندی API از Management API به Gateway runtime. یک API تا زمانی که deploy نشود، فعال نیست. |
| **Dashboard Settings** | رابط کاربری کنسول مدیریت Gravitee. تمام اقداماتی که در این راهنما به «داشبورد» اشاره می‌کنند به این رابط وب مربوط می‌شوند که در آدرس `https://console.company.com` (پورت `8084` به‌صورت پیش‌فرض) در دسترس است. |

---

## ۲. ایجاد و انتشار اولین API

### ۲.۱ ایجاد یک API

**هدف:** ثبت یک سرویس backend به نام `service-a` پشت Gravitee Gateway.

1. داشبورد را باز کنید ← نوار کناری چپ ← **APIs** ← روی **+ Create API** کلیک کنید.
2. **Create a V4 API** را انتخاب کنید (مدل بومی Gravitee 4.x).
3. تب **General** را پر کنید:
   - **Name:** `service-a`
   - **Version:** `1.0.0`
   - **Description:** `Internal Service A — exposed via Gravitee`
4. روی **Next** کلیک کنید ← تب **Entrypoints**:
   - **HTTP Proxy** را به‌عنوان نوع entrypoint انتخاب کنید.
   - **Path:** `/service-a/v1`
   - virtual host را خالی بگذارید مگر اینکه از مسیریابی multi-domain استفاده می‌کنید.
5. روی **Next** کلیک کنید ← تب **Endpoints**:
   - روی **+ Add endpoint group** کلیک کنید.
   - **Name:** `service-a-backend`
   - **Target URL:** `http://service-a.internal:8080`
   - **Load Balancing** را روی `Round Robin` تنظیم کنید (در صورت داشتن یک instance، تنظیم کنید).
6. روی **Next** کلیک کنید ← تب **Security** — فعلاً از آن بگذرید (در بخش ۲.۲ توضیح داده شده).
7. روی **Next** کلیک کنید ← خلاصه را مرور کنید ← روی **Create & deploy** یا **Save** کلیک کنید.

> در این مرحله API وجود دارد اما **هیچ Plan**ی ندارد، به این معنی که هیچ مصرف‌کننده‌ای نمی‌تواند مشترک شود. به بخش ۲.۲ بروید.

---

### ۲.۲ افزودن امنیت — API Key

**هدف:** محافظت از API با احراز هویت API Key.

1. در داشبورد ← **APIs** ← `service-a` را باز کنید.
2. نوار کناری چپ ← **Plans** ← روی **+ Add plan** کلیک کنید.
3. **نوع Plan:** **API Key** را انتخاب کنید.
4. موارد زیر را پر کنید:
   - **Name:** `service-a-apikey-plan`
   - **Description:** `API Key access for service-a`
   - **Security:** `API Key` (از پیش انتخاب شده)
5. **Validation:** روی **Automatic** تنظیم کنید (یا Manual اگر می‌خواهید هر اشتراک را تأیید کنید).
6. روی **Next** کلیک کنید ← به‌صورت اختیاری rate limiting اضافه کنید (بخش ۳.۱) ← روی **Save** کلیک کنید.
7. روی **Publish** کنار plan کلیک کنید تا قابل اشتراک شود.
8. به **Deployment** بروید ← روی **Deploy** کلیک کنید تا تغییرات به Gateway push شوند.

**برای ایجاد API Key برای یک مصرف‌کننده:**

1. داشبورد ← **Applications** ← یک Application ایجاد کنید (name: `consumer-app-1`).
2. داخل application ← **Subscriptions** ← **+ Subscribe** ← `service-a` را انتخاب کنید ← `service-a-apikey-plan` را انتخاب کنید.
3. پس از تأیید، API Key در **Subscriptions → API Keys** ظاهر می‌شود.

**استفاده از API Key:**

```http
GET https://gateway.company.com/service-a/v1/health
X-Gravitee-Api-Key: <your-api-key>
```

---

### ۲.۳ افزودن امنیت — JWT از طریق Keycloak

**هدف:** پذیرش JWTهایی که توسط Keycloak صادر شده‌اند در یک plan جداگانه.

**پیش‌نیازها در Keycloak:**
- یک Realm به نام `company-realm` وجود دارد.
- یک client به نام `gravitee-gateway` با **Access Type:** `confidential` وجود دارد.
- JWKS URI را دریافت کنید: `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/certs`

**مراحل:**

1. داشبورد ← **APIs** ← `service-a` را باز کنید ← **Plans** ← **+ Add plan**.
2. **نوع Plan:** **JWT** را انتخاب کنید.
3. موارد زیر را پر کنید:
   - **Name:** `service-a-jwt-plan`
   - **Security:** `JWT`
4. در بخش پیکربندی **JWT**:
   - **Signature algorithm:** `RS256`
   - **JWKS resolver:** `JWKS_URL`
   - **JWKS URL:** `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/certs`
   - **Issuer:** `https://keycloak.company.com/realms/company-realm`
   - **Audiences:** `gravitee-gateway` (باید با claim ‌`aud` در JWT مطابقت داشته باشد)
5. روی **Save** ← **Publish** ← **Deploy** کلیک کنید.

**درخواست مصرف‌کننده:**

```http
GET https://gateway.company.com/service-a/v1/resource
Authorization: Bearer <keycloak-issued-jwt>
```

---

### ۲.۴ افزودن Policy

**هدف:** اضافه کردن منطق پردازشی (مثلاً افزودن header، تبدیل پاسخ) به flow API.

1. داشبورد ← **APIs** ← `service-a` را باز کنید ← **Policy Studio**.
2. canvas فازهای **Request** و **Response** را نشان می‌دهد. روی **+ Add policy** در فاز flow که می‌خواهید اعمال کنید کلیک کنید.
3. مثال — **افزودن یک custom request header:**
   - Phase: **Request**
   - Policy: **Transform Headers**
   - Action: **Add / Replace**
   - Header name: `X-Internal-Source`
   - Header value: `gravitee-gateway`
4. روی **Save** ← **Deploy** کلیک کنید.

> Policyها به ترتیب فهرست‌شده اجرا می‌شوند. برای تغییر ترتیب، آن‌ها را روی canvas بکشید.

**Policyهای رایج و کاربرد آن‌ها:**

| Policy | کاربرد معمول |
|---|---|
| Transform Headers | تزریق، حذف یا بازنویسی HTTP headerها |
| Rate Limit | محدود کردن درخواست‌ها (بخش ۳.۱) |
| JWT | اعتبارسنجی توکن‌های JWT |
| Callout HTTP | فراخوانی یک HTTP endpoint خارجی در طول flow (مثلاً دریافت توکن — بخش ۴) |
| Cache | ذخیره‌سازی پاسخ‌های upstream یا داده‌های میانی |
| Assign Content | بازنویسی body پاسخ |
| GeoIP Filtering | مسدود یا مجاز کردن بر اساس موقعیت جغرافیایی |
| Resource Filtering | محدود کردن دسترسی بر اساس HTTP method یا path |

---

### ۲.۵ انتشار API

یک API باید منتشر شود تا در Developer Portal ظاهر شده و از طریق Gateway قابل فراخوانی باشد.

1. داشبورد ← **APIs** ← `service-a` را باز کنید.
2. بالا-راست ← روی دکمه **Publish** (آیکون ابر) کلیک کنید ← تأیید کنید.
3. مطمئن شوید **State** API روی **Started** است.
4. به **Deployment** بروید ← اگر تغییرات در انتظار هستند (با یک badge زرد نشان داده می‌شود) روی **Deploy** کلیک کنید.

> **مهم:** ذخیره تغییرات در داشبورد به‌طور خودکار Gateway را **به‌روز نمی‌کند**. همیشه پس از تغییرات پیکربندی روی **Deploy** کلیک کنید.

---

### ۲.۶ افزودن مستندات API

1. داشبورد ← **APIs** ← `service-a` را باز کنید ← نوار کناری چپ ← **Documentation**.
2. روی **+ Add page** کلیک کنید.
3. فرمت را انتخاب کنید:
   - **Markdown** — برای مستندات روایی.
   - **OpenAPI (Swagger)** — `openapi.yaml` را paste یا آپلود کنید.
   - **AsyncAPI** — برای APIهای event-driven.
4. برای OpenAPI:
   - **Source:** `File` یا `URL` (مثلاً `http://service-a.internal:8080/v3/api-docs`).
   - گزینه **Published** را روی `ON` قرار دهید.
5. روی **Save** ← **Deploy** کلیک کنید.

مستندات در Developer Portal زیر صفحه API ظاهر می‌شوند.

---

## ۳. آموزش‌های کاربردی

---

### ۳.۱ محدودیت نرخ درخواست برای REST APIها

**هدف:** محدود کردن مصرف‌کنندگان به تعداد مشخصی درخواست در یک بازه زمانی.

1. داشبورد ← **APIs** ← API خود را باز کنید ← **Policy Studio**.
2. **Plan flow** که می‌خواهید rate limit روی آن اعمال شود انتخاب کنید (مثلاً `service-a-apikey-plan`).
3. روی **+ Add policy** کلیک کنید ← فاز **Request** ← **Rate Limit** را انتخاب کنید.
4. پیکربندی کنید:
   - **Key:** `{#request.headers['X-Gravitee-Api-Key']}` (به ازای هر API key) یا `{#context.attributes['application']}` (به ازای هر application)
   - **Max requests:** `100`
   - **Time period:** `1`
   - **Time unit:** `MINUTES`
   - **Limit header:** فعال کنید (در پاسخ‌ها `X-Rate-Limit-Remaining` ارسال می‌شود)
5. روی **Save** ← **Deploy** کلیک کنید.

**روش جایگزین — تنظیم rate limiting در سطح Plan:**

1. داشبورد ← **APIs** ← **Plans** ← plan را ویرایش کنید.
2. در بخش **Rate Limiting** ← toggle را ON کنید ← همان مقادیر را تنظیم کنید.
3. **Save** ← **Deploy**.

> Rate limiting در سطح Plan به‌صورت سراسری روی همه flow‌ها اعمال می‌شود. سطح Policy کنترل دقیق‌تری به ازای هر path یا method می‌دهد.

---

### ۳.۲ پیکربندی امنیت JWT

**هدف:** پیکربندی کامل گام‌به‌گام plan JWT با Keycloak به‌عنوان identity provider.

**مرحله ۱ — آماده‌سازی Keycloak:**

1. کنسول ادمین Keycloak ← `company-realm` را انتخاب کنید ← **Clients** ← **Create**.
2. تنظیمات client:
   - **Client ID:** `api-consumer-client`
   - **Access Type:** `confidential`
   - **Standard Flow:** OFF
   - **Direct Access Grants:** OFF
   - **Service Accounts:** ON (برای client_credentials در صورت نیاز)
3. **Save** ← **Client Secret** را از تب **Credentials** کپی کنید.
4. تأیید کنید که JWKS endpoint در دسترس است:
   ```
   GET https://keycloak.company.com/realms/company-realm/protocol/openid-connect/certs
   ```

**مرحله ۲ — ایجاد JWT Plan در Gravitee:**

1. داشبورد ← **APIs** ← API خود را باز کنید ← **Plans** ← **+ Add plan** ← **JWT**.
2. طبق بخش ۲.۳ پیکربندی کنید.
3. علاوه بر این تنظیم کنید:
   - **Extract JWT Claims:** ON ← این claimها را به‌صورت `{#context.attributes['jwt.claims']['claim-name']}` در policyها در دسترس می‌گذارد.
   - **Client ID Claim:** `azp` یا `client_id` (با آنچه Keycloak در توکن قرار می‌دهد مطابقت دهید).

**مرحله ۳ — تست:**

دریافت توکن از Keycloak:
```bash
curl -X POST https://keycloak.company.com/realms/company-realm/protocol/openid-connect/token \
  -d "grant_type=client_credentials" \
  -d "client_id=api-consumer-client" \
  -d "client_secret=<client-secret>"
```

فراخوانی API:
```bash
curl -H "Authorization: Bearer <access_token>" \
  https://gateway.company.com/service-a/v1/resource
```

---

### ۳.۳ افزودن RBAC به پلن‌های JWT

**هدف:** محدود کردن دسترسی به path‌ها یا method‌های خاص بر اساس roles داخل JWT.

**مرحله ۱ — افزودن roles به توکن‌های Keycloak:**

1. Keycloak ← `company-realm` ← **Clients** ← `api-consumer-client` ← **Client Roles** ← **Add Role**.
   - نمونه roleها: `read`، `write`، `admin`
2. roleها را به کاربران یا service accountها اختصاص دهید: **Users** ← کاربر را انتخاب کنید ← **Role Mappings** ← **Client Roles** ← `api-consumer-client` را انتخاب کنید ← roleها را اضافه کنید.
3. تأیید کنید که JWT شامل roleها است:
   ```json
   {
     "resource_access": {
       "api-consumer-client": {
         "roles": ["read"]
       }
     }
   }
   ```

**مرحله ۲ — افزودن Resource Filtering policy در Gravitee:**

1. داشبورد ← **APIs** ← API خود را باز کنید ← **Policy Studio**.
2. JWT plan flow را انتخاب کنید ← **+ Add policy** ← فاز **Request** ← **Resource Filtering**.
3. قوانین را پیکربندی کنید:

   | Path | Methods | Allowed | Role expression |
   |---|---|---|---|
   | `/service-a/v1/**` | GET | YES | `{#context.attributes['jwt.claims']['resource_access']['api-consumer-client']['roles'].contains('read')}` |
   | `/service-a/v1/**` | POST, PUT, DELETE | YES | `{#context.attributes['jwt.claims']['resource_access']['api-consumer-client']['roles'].contains('write')}` |

4. روی **Save** ← **Deploy** کلیک کنید.

> اگر عبارت role به `false` ارزیابی شود، Gateway قبل از رسیدن درخواست به backend پاسخ `403 Forbidden` برمی‌گرداند.

---

### ۳.۴ پیکربندی Dynamic Client Registration یا DCR

**هدف:** اجازه دادن به Developer Portal برای ایجاد خودکار clientهای Keycloak هنگامی که یک Application ثبت می‌شود.

**مرحله ۱ — پیکربندی Keycloak برای DCR:**

1. Keycloak ← `company-realm` ← **Realm Settings** ← **Client Registration** ← **Client Registration Policies**.
2. **Trusted Hosts** را فعال کنید و host مدیریت Gravitee خود را در whitelist قرار دهید.
3. یک **Registration Access Token** ایجاد کنید (یا از یک confidential client با نقش `manage-clients` استفاده کنید):
   - **Clients** ← **Create** ← Client ID: `gravitee-dcr-client`
   - **Access Type:** `confidential`
   - **Service Accounts:** ON
   - **Service Account Roles** ← **Client Roles** ← `realm-management` ← `manage-clients` را اضافه کنید
4. **Client Secret** را یادداشت کنید.

**مرحله ۲ — پیکربندی DCR در Gravitee:**

1. داشبورد ← **Settings** ← **Authentication** ← **+ Add identity provider** ← **OpenID Connect**.
2. پر کنید:
   - **Name:** `keycloak-company-realm`
   - **Client ID:** `gravitee-dcr-client`
   - **Client Secret:** `<secret از مرحله ۱>`
   - **Token Endpoint:** `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/token`
   - **Authorization Endpoint:** `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/auth`
   - **Userinfo Endpoint:** `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/userinfo`
   - **JWKS URI:** `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/certs`
3. **Save**.

**مرحله ۳ — فعال‌سازی DCR روی یک Plan:**

1. داشبورد ← **APIs** ← API خود را باز کنید ← **Plans** ← plan OAuth2 یا JWT را ویرایش کنید.
2. **Dynamic Client Registration** را فعال کنید.
3. identity provider پیکربندی‌شده در بالا را انتخاب کنید.
4. **Save** ← **Deploy**.

از این پس هنگامی که یک مصرف‌کننده در Portal یک Application ایجاد می‌کند و به این plan مشترک می‌شود، Gravitee به‌طور خودکار یک client در Keycloak ثبت کرده و اعتبارنامه‌ها را به مصرف‌کننده برمی‌گرداند.

---

### ۳.۵ امن‌سازی و انتشار سرویس‌های gRPC

**هدف:** انتشار یک سرویس backend gRPC از طریق Gravitee Gateway.

**پیش‌نیازها:**
- Gravitee 4.x Gateway با پشتیبانی از gRPC فعال.
- سرویس backend gRPC در حال اجرا در `grpc://service-a.internal:50051`.
- فایل Proto برای `service-a`.

**مرحله ۱ — ایجاد API:**

1. داشبورد ← **APIs** ← **+ Create API** ← **V4 API**.
2. تب **Entrypoints** ← **gRPC** را انتخاب کنید.
   - **Path:** `/service-a.ServiceA` (باید با package و نام سرویس gRPC مطابقت داشته باشد).
   - **Host:** `gateway.company.com`
   - **Port:** `9443` (پورت listener gRPC Gravitee — با تیم ops خود تأیید کنید).
3. تب **Endpoints** ← **+ Add endpoint group**:
   - **Target:** `grpc://service-a.internal:50051`
   - اگر سرویس backend gRPC نیاز دارد، **TLS** را فعال کنید.
4. تب **Security** ← **API Key** یا **JWT plan** را بر اساس نیاز انتخاب کنید.
5. **Save** ← **Deploy**.

**مرحله ۲ — امنیت API Key (metadata در gRPC):**

مصرف‌کنندگان gRPC، API Key را در metadata درخواست ارسال می‌کنند:
```
Metadata:
  X-Gravitee-Api-Key: <api-key>
```

**مرحله ۳ — تست با grpcurl:**

```bash
grpcurl \
  -H "X-Gravitee-Api-Key: <api-key>" \
  -proto service-a.proto \
  gateway.company.com:9443 \
  service_a.ServiceA/MethodName
```

> برای mutual TLS (mTLS) بین Gateway و سرویس backend gRPC، تنظیمات **SSL** endpoint را در endpoint group پیکربندی کرده و certificate و private key client را تأمین کنید.

---

### ۳.۶ انتشار سرویس‌های SOAP به‌عنوان REST API

**هدف:** پوشاندن یک backend SOAP قدیمی و انتشار آن به‌عنوان REST API از طریق Gravitee.

**مرحله ۱ — ایجاد API:**

1. داشبورد ← **APIs** ← **+ Create API** ← **V4 API**.
2. تب **Entrypoints** ← **HTTP Proxy**.
   - **Path:** `/legacy-service/v1`
3. تب **Endpoints** ← URL backend:
   - `http://legacy-service.internal:8080/ws/LegacyService`
4. **Save**.

**مرحله ۲ — افزودن policyهای تبدیل SOAP به REST:**

1. داشبورد ← **APIs** ← API را باز کنید ← **Policy Studio**.
2. فاز **Request** ← **+ Add policy** ← **Transform Headers**:
   - افزودن header: `Content-Type` ← `text/xml; charset=utf-8`
   - افزودن header: `SOAPAction` ← `"urn:GetResource"` (با action WSDL مطابقت دهید)
3. فاز **Request** ← **+ Add policy** ← **Assign Content**:
   - body REST ورودی را با یک SOAP envelope جایگزین کنید:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
     <soap:Body>
       <GetResource xmlns="urn:legacy-service">
         <Id>{#request.params['id']}</Id>
       </GetResource>
     </soap:Body>
   </soap:Envelope>
   ```
   - از `{#request.params['field']}` یا `{#request.content}` برای نگاشت ورودی‌های REST به فیلدهای SOAP استفاده کنید.
4. فاز **Response** ← **+ Add policy** ← **Transform Headers**:
   - header `Content-Type` را با `application/json` جایگزین کنید.
5. فاز **Response** ← **+ Add policy** ← **Assign Content** یا **XSLT Transformation**:
   - از یک stylesheet XSLT برای استخراج body پاسخ SOAP و تبدیل آن به JSON استفاده کنید.
6. روی **Save** ← **Deploy** کلیک کنید.

**درخواست مصرف‌کننده (مانند یک REST call معمولی به نظر می‌رسد):**

```bash
curl "https://gateway.company.com/legacy-service/v1/resource?id=123" \
  -H "X-Gravitee-Api-Key: <api-key>"
```

---

### ۳.۷ ایجاد و انتشار API از طریق Management API

**هدف:** خودکارسازی ایجاد API بدون استفاده از داشبورد — مفید برای pipeline‌های CI/CD.

**مرحله ۱ — احراز هویت:**

```bash
TOKEN=$(curl -s -X POST https://console.company.com/management/organizations/DEFAULT/environments/DEFAULT/user/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"<password>"}' | jq -r '.token')
```

**مرحله ۲ — ایجاد API:**

```bash
curl -X POST \
  "https://console.company.com/management/organizations/DEFAULT/environments/DEFAULT/apis" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "service-b",
    "version": "1.0.0",
    "description": "Service B via Management API",
    "proxy": {
      "virtual_hosts": [{ "path": "/service-b/v1" }],
      "groups": [{
        "name": "service-b-backend",
        "endpoints": [{
          "name": "default",
          "target": "http://service-b.internal:8081",
          "weight": 1
        }]
      }]
    }
  }'
```

`id` بازگشتی در پاسخ را یادداشت کنید (مثلاً `api_id=abc-123`).

**مرحله ۳ — ایجاد Plan:**

```bash
curl -X POST \
  "https://console.company.com/management/organizations/DEFAULT/environments/DEFAULT/apis/abc-123/plans" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "service-b-apikey-plan",
    "security": "API_KEY",
    "status": "PUBLISHED",
    "validation": "AUTO"
  }'
```

**مرحله ۴ — انتشار و Deploy:**

```bash
# انتشار API در portal
curl -X POST \
  "https://console.company.com/management/organizations/DEFAULT/environments/DEFAULT/apis/abc-123/publish" \
  -H "Authorization: Bearer $TOKEN"

# Deploy به Gateway
curl -X POST \
  "https://console.company.com/management/organizations/DEFAULT/environments/DEFAULT/apis/abc-123/deployments" \
  -H "Authorization: Bearer $TOKEN"
```

> برای مشخصات کامل API، به Gravitee Management API Swagger UI در آدرس `https://console.company.com/management/swagger-ui` مراجعه کنید.

---

### ۳.۸ اتصال یک Endpoint با SSE

**هدف:** انتشار یک جریان backend از نوع Server-Sent Events یا SSE از طریق Gravitee Gateway.

**مرحله ۱ — ایجاد API:**

1. داشبورد ← **APIs** ← **+ Create API** ← **V4 API**.
2. تب **Entrypoints** ← **HTTP GET** را انتخاب کنید (Gravitee 4.x از طریق HTTP GET entrypoint با streaming، SSE را نشان می‌دهد).
3. **Path:** `/service-a/v1/events`
4. تب **Endpoints** ← **+ Add endpoint group**:
   - **Type:** `HTTP`
   - **Target URL:** `http://service-a.internal:8080/events` (endpoint جریان SSE در backend)
5. در پیکربندی endpoint ← **Allow chunked encoding** و **Keep-alive** را فعال کنید.

**مرحله ۲ — پیکربندی پاسخ SSE:**

1. **Policy Studio** ← فاز **Response** ← **+ Add policy** ← **Transform Headers**:
   - `Content-Type` را روی `text/event-stream` تنظیم کنید
   - `Cache-Control` را روی `no-cache` تنظیم کنید
   - `Connection` را روی `keep-alive` تنظیم کنید
2. **Save** ← **Deploy**.

**مرحله ۳ — تست:**

```bash
curl -N \
  -H "X-Gravitee-Api-Key: <api-key>" \
  https://gateway.company.com/service-a/v1/events
```

خروجی مورد انتظار:
```
data: {"event":"status","value":"ok"}

data: {"event":"update","value":"new-data"}
```

---

## ۴. بررسی عمیق: جریان شفاف توکن سرویس‌به‌سرویس

### مرور کلی

این بخش مهم‌ترین الگوی production را پوشش می‌دهد: **کلاینت بدون هیچ توکنی درخواستی به Gateway ارسال می‌کند و Gateway به‌طور شفاف یک توکن از Keycloak با استفاده از `client_credentials` دریافت کرده، سپس آن را قبل از فوروارد کردن درخواست به سرویس downstream تزریق می‌کند.**

سرویس downstream (مثلاً `service-b`) محافظت‌شده است و به یک توکن Bearer معتبر نیاز دارد. کلاینت فراخواننده (مثلاً یک frontend، اپ موبایل یا سرویس دیگر) **کاملاً از تبادل توکن بی‌خبر است**.

```
Client
  │
  │  Request (API Key or no token)
  ▼
Gravitee Gateway
  │
  ├──[1] Callout HTTP Policy → POST /token to Keycloak
  │         grant_type=client_credentials
  │         client_id=gateway-internal-client
  │         client_secret=<secret>
  │
  ├──[2] Extract access_token from Keycloak response
  │
  ├──[3] Cache the token (avoid calling Keycloak on every request)
  │
  ├──[4] Inject:  Authorization: Bearer <access_token>
  │
  ▼
service-b.internal:8081
  │
  (validates token against Keycloak JWKS — token is trusted)
```

---

### ۴.۱ راه‌اندازی Keycloak

**مرحله ۱ — ایجاد client داخلی Gateway در Keycloak:**

1. کنسول ادمین Keycloak ← `company-realm` ← **Clients** ← **Create**.
2. پیکربندی کنید:
   - **Client ID:** `gateway-internal-client`
   - **Access Type:** `confidential`
   - **Standard Flow Enabled:** OFF
   - **Direct Access Grants:** OFF
   - **Service Accounts Enabled:** ON ← برای `client_credentials` الزامی است
3. **Save** ← به تب **Credentials** بروید ← **Client Secret** را کپی کنید.

**مرحله ۲ — اختصاص scope/roleهای صحیح:**

1. داخل `gateway-internal-client` ← تب **Service Account Roles**.
2. roleهایی که `service-b` در توکن انتظار دارد را اختصاص دهید (مثلاً `service-b-caller`).

**مرحله ۳ — تأیید عملکرد token endpoint:**

```bash
curl -X POST \
  https://keycloak.company.com/realms/company-realm/protocol/openid-connect/token \
  -d "grant_type=client_credentials" \
  -d "client_id=gateway-internal-client" \
  -d "client_secret=<secret>"
```

پاسخ مورد انتظار:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5...",
  "expires_in": 300,
  "token_type": "Bearer"
}
```

مقدار `expires_in` را یادداشت کنید (مثلاً `300` ثانیه). از آن در TTL cache استفاده خواهید کرد.

---

### ۴.۲ راه‌اندازی Gravitee — API و Plan

**مرحله ۱ — ایجاد یا باز کردن API:**

این flow روی API که **به `service-b` پراکسی می‌کند** پیکربندی می‌شود. اگر هنوز آن را ایجاد نکرده‌اید:

1. داشبورد ← **APIs** ← **+ Create API** ← **V4 API**.
2. **Entrypoints:** `/service-b/v1`
3. **Endpoints:** `http://service-b.internal:8081`
4. **Plan:** `API Key` (کلاینت‌ها با API key به Gateway فراخوانی می‌کنند — تبادل توکن به‌صورت داخلی انجام می‌شود).
5. **Save**.

> کلاینت با **API Key** به Gateway احراز هویت می‌کند. تبادل توکن با Keycloak یک **عملیات داخلی Gateway** است — برای کلاینت نامرئی.

---

### ۴.۳ پیکربندی Cache Resource

قبل از ساختن flow، یک cache resource مشترک برای ذخیره توکن بین درخواست‌ها ایجاد کنید.

1. داشبورد ← **APIs** ← API را باز کنید ← نوار کناری چپ ← **Resources**.
2. روی **+ Add resource** کلیک کنید ← **Cache Resource**.
3. پیکربندی کنید:
   - **Name:** `keycloak-token-cache`
   - **Cache Resource Name (Key Prefix):** `kc-token`
   - **Time to Live (TTL):** `270` (کمی کمتر از `expires_in` Keycloak که ۳۰۰ است تا از استفاده توکن منقضی‌شده جلوگیری شود)
   - **Max entries:** `100`
4. **Save**.

---

### ۴.۴ ساختن Policy Flow — گام‌به‌گام

به **APIs** ← API خود ← **Policy Studio** ← **Request** flow plan بروید.

policyها را دقیقاً به این ترتیب اضافه کنید:

```
[Request Phase]
  1. Cache Lookup      ← بررسی می‌کند آیا توکن از قبل cache شده است
  2. Callout HTTP      ← توکن را از Keycloak دریافت می‌کند (در صورت cache hit رد می‌شود)
  3. Assign Attributes ← access_token را از پاسخ callout استخراج می‌کند
  4. Cache Store       ← توکن را در cache ذخیره می‌کند (در صورت cache hit رد می‌شود)
  5. Transform Headers ← Authorization: Bearer <token> را تزریق می‌کند
```

---

#### Policy 1 — Cache Lookup

1. **+ Add policy** ← فاز **Request** ← **Cache**.
2. روی حالت **Lookup** تنظیم کنید.
3. پیکربندی کنید:
   - **Cache Resource:** `keycloak-token-cache`
   - **Cache Key:** `gateway-internal-client-token` (ثابت — همه درخواست‌ها یک توکن را به اشتراک می‌گذارند چون service account است)
   - **Time to Live:** خالی بگذارید (از TTL resource استفاده می‌کند)
4. **On Cache Hit:** **Skip remaining policies in this phase up to Cache Store policy** را انتخاب کنید — یا از condition روی Callout policy استفاده کنید (مرحله بعد را ببینید).
5. **Save**.

> وقتی cache یک توکن معتبر دارد، Callout HTTP policy رد می‌شود و flow مستقیماً به تزریق header می‌رود.

---

#### Policy 2 — Callout HTTP (دریافت توکن از Keycloak)

1. **+ Add policy** ← فاز **Request** ← **Callout HTTP**.
2. پیکربندی کنید:

   | فیلد | مقدار |
   |---|---|
   | **HTTP Method** | `POST` |
   | **URL** | `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/token` |
   | **Request Body** | `grant_type=client_credentials&client_id=gateway-internal-client&client_secret=<secret>` |
   | **Content-Type Header** | `application/x-www-form-urlencoded` |
   | **Response Variable** | `keycloak-response` |
   | **Fire & Forget** | OFF (به پاسخ نیاز داریم) |
   | **Exit on Error** | ON (در صورت عدم دسترسی به Keycloak متوقف شود) |
   | **Error Status** | `503` |

3. **Condition** (برای رد شدن در صورت cache hit):
   - **Condition** را فعال کنید ← وارد کنید:
     ```
     {#context.attributes['keycloak-token-cache'] == null}
     ```
   - این اطمینان می‌دهد که callout فقط وقتی cache توکن **ندارد** فعال شود.

4. **Save**.

> **نکته امنیتی:** `client_secret` را به‌صورت plain text در یک سیستم production hardcode نکنید. از یکپارچگی **Secret Provider** Gravitee یا ذخیره آن در **Resource** از نوع `OAuth2` استفاده کنید. بخش ۴.۶ را ببینید.

---

#### Policy 3 — Assign Attributes (استخراج توکن)

1. **+ Add policy** ← فاز **Request** ← **Assign Attributes**.
2. یک attribute اضافه کنید:

   | نام Attribute | مقدار Attribute |
   |---|---|
   | `internal-bearer-token` | `{#jsonPath(#context.attributes['keycloak-response'].content, '$.access_token')}` |

3. **Condition:**
   ```
   {#context.attributes['keycloak-response'] != null}
   ```
   (فقط در صورتی اجرا شود که callout واقعاً اجرا شده باشد.)

4. **Save**.

---

#### Policy 4 — Cache Store (ذخیره توکن)

1. **+ Add policy** ← فاز **Request** ← **Cache** (نمونه دوم).
2. روی حالت **Store** تنظیم کنید.
3. پیکربندی کنید:
   - **Cache Resource:** `keycloak-token-cache`
   - **Cache Key:** `gateway-internal-client-token`
   - **Value to Cache:** `{#context.attributes['internal-bearer-token']}`
   - **Time to Live:** `270`
4. **Condition:**
   ```
   {#context.attributes['internal-bearer-token'] != null}
   ```
5. **Save**.

---

#### Policy 5 — Transform Headers (تزریق Bearer Token)

1. **+ Add policy** ← فاز **Request** ← **Transform Headers**.
2. **Actions:**

   | عمل | نام Header | مقدار Header |
   |---|---|---|
   | **Add / Replace** | `Authorization` | `Bearer {#context.attributes['internal-bearer-token']}` |

3. **در صورت Cache Hit:** اگر از بازیابی توکن مبتنی بر cache استفاده می‌کنید، مقدار را برای خواندن از cache attribute تنظیم کنید:
   ```
   Bearer {#context.attributes['keycloak-token-cache'] != null
     ? #context.attributes['keycloak-token-cache']
     : #context.attributes['internal-bearer-token']}
   ```
   یا با همیشه پر کردن `internal-bearer-token` از هر دو منبع در Policy 3 ساده‌تر کنید.

4. **Save** ← **Deploy**.

---

### ۴.۵ خلاصه کامل Flow

پس از deploy، جریان end-to-end برای هر درخواست کلاینت به این شکل است:

```
1. کلاینت ارسال می‌کند:
   GET https://gateway.company.com/service-b/v1/resource
   X-Gravitee-Api-Key: <api-key>

2. Gateway API Key را اعتبارسنجی می‌کند ← موفق.

3. Cache Lookup:
   - HIT  ← توکن را از cache بارگذاری می‌کند ← به مرحله ۶ بروید.
   - MISS ← به مرحله ۴ ادامه دهید.

4. Callout HTTP ← POST به Keycloak:
   grant_type=client_credentials
   client_id=gateway-internal-client
   client_secret=<secret>
   ← پاسخ: { "access_token": "eyJ...", "expires_in": 300 }

5. استخراج + Cache:
   - access_token را در context attribute 'internal-bearer-token' ذخیره می‌کند.
   - در 'keycloak-token-cache' با TTL=270s ذخیره می‌کند.

6. Transform Headers:
   - هر Authorization header ارسال‌شده توسط کلاینت را حذف یا نادیده می‌گیرد.
   - تنظیم می‌کند: Authorization: Bearer eyJ...

7. فوروارد به downstream:
   GET http://service-b.internal:8081/resource
   Authorization: Bearer eyJ...

8. service-b توکن را در برابر Keycloak JWKS اعتبارسنجی می‌کند ← موفق.

9. پاسخ به‌طور معمول به کلاینت برمی‌گردد.
```

**کلاینت هرگز توکن را نمی‌بیند. کلاینت هرگز نیازی به اکانت Keycloak ندارد. سرویس downstream کاملاً محافظت‌شده است.**

---

### ۴.۶ امن‌سازی Client Secret (الزام Production)

Hardcode کردن `client_secret` در body یک Callout policy برای production **قابل قبول نیست**. از یکی از این رویکردها استفاده کنید:

**گزینه A — Gravitee Secret Provider (توصیه‌شده):**

1. داشبورد ← **Settings** ← **Secret Providers** ← یک Vault یا Kubernetes Secrets backend پیکربندی کنید.
2. به secret در policy با استفاده از این دستور ارجاع دهید:
   ```
   {#secrets.get('gateway-internal-client-secret')}
   ```

**گزینه B — OAuth2 Resource:**

1. داشبورد ← **APIs** ← **Resources** ← **+ Add resource** ← **OAuth2 - Keycloak Adapter**.
2. با اعتبارنامه‌های `gateway-internal-client` پیکربندی کنید.
3. در Callout policy، body POST دستی را با ارجاع به این resource جایگزین کنید — Gravitee بازیابی و caching توکن را به‌طور خودکار مدیریت می‌کند.

   > این تمیزترین رویکرد production است. OAuth2 Resource چرخه حیات، refresh و caching توکن را به‌صورت داخلی مدیریت می‌کند.

**گزینه C — Environment Variables:**

Secret را به‌عنوان یک Gateway environment variable تنظیم کنید (مثلاً `GATEWAY_CLIENT_SECRET`) و به آن ارجاع دهید:
```
{#system.getenv('GATEWAY_CLIENT_SECRET')}
```

---

### ۴.۷ حذف Authorization Header کلاینت (اختیاری اما توصیه‌شده)

اگر احتمالی وجود دارد که کلاینت یک `Authorization` header ارسال کند، قبل از تزریق توکن داخلی آن را حذف کنید.

1. **Policy Studio** ← فاز **Request** ← **Transform Headers** policy (قبل از injection policy اضافه کنید).
2. **Actions:**
   - **Remove:** `Authorization`
3. این policy را **قبل از** Callout HTTP policy در زنجیر قرار دهید.

---

### ۴.۸ تست Flow کامل

**تست بدون توکن از سمت کلاینت:**

```bash
curl -v \
  -H "X-Gravitee-Api-Key: <api-key>" \
  https://gateway.company.com/service-b/v1/resource
```

**تأیید در سمت service-b** (از طریق log یا یک debug endpoint) که درخواست با این header رسیده است:
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

**تأیید عملکرد cache** با بررسی اینکه درخواست دوم بدون یک Keycloak callout جدید کامل می‌شود. می‌توانید این را از طریق موارد زیر مشاهده کنید:
- Gravitee Gateway logs (به‌طور موقت `DEBUG` را فعال کنید).
- کنسول ادمین Keycloak ← **Events** ← تأیید کنید که فقط یک رویداد صدور توکن برای چندین فراخوانی API در پنجره TTL وجود دارد.

---

### ۴.۹ مرجع پیکربندی Keycloak

| تنظیم | مقدار |
|---|---|
| Realm | `company-realm` |
| Token Endpoint | `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/token` |
| JWKS URI | `https://keycloak.company.com/realms/company-realm/protocol/openid-connect/certs` |
| Internal Client ID | `gateway-internal-client` |
| Grant Type | `client_credentials` |
| Token TTL (Keycloak) | `300s` (در Keycloak realm ← تب Tokens پیکربندی کنید) |
| Cache TTL (Gravitee) | `270s` (حاشیه امنیت ۱۰ ثانیه) |

---

## ۵. ثبت وقایع و تحلیل API

Gravitee دو دسته متمایز از داده را ثبت می‌کند که پیش از ساختن هر workflow ممیزی یا تحلیل باید با آن‌ها آشنا باشید:

- **Audit Logs** — چه کسی چه چیزی را و چه زمانی تغییر داده. رویدادهای پیکربندی: API ایجاد شد، plan منتشر شد، اشتراک تأیید شد، policy تغییر کرد، deploy انجام شد. اینها رکوردهای زمان نوشتن اقدامات مدیریتی هستند.
- **Analytics** — چه ترافیکی در جریان است. معیارهای runtime: تعداد درخواست، latency، کد وضعیت، تفکیک مصرف‌کننده، نرخ خطا. اینها رکوردهای زمان خواندن فعالیت Gateway هستند.

هر دو از داشبورد بدون نیاز به ابزار خارجی قابل دسترسی هستند، هرچند هر دو قابل export نیز هستند.

---

### ۵.۱ آنچه ثبت می‌شود

Gravitee به‌طور خودکار یک audit trail برای تمام اقدامات مدیریتی ایجاد می‌کند. رویدادهای زیر در **سطح پلتفرم** و **سطح API** ثبت می‌شوند:

| دسته رویداد | نمونه رویدادهای ثبت‌شده |
|---|---|
| **چرخه حیات API** | Created، Updated، Published، Unpublished، Deleted، Deployed |
| **مدیریت Plan** | Plan created، Plan published، Plan closed، Plan updated |
| **اشتراک** | Subscription created، Subscription approved، Subscription rejected، Subscription closed، API Key renewed |
| **Policy / Flow** | Policy added، Policy removed، Policy reordered، Flow updated |
| **Application** | Application created، Application updated، Application archived |
| **اعضا و دسترسی** | Member added، Role changed، Member removed |
| **احراز هویت** | Admin login، تلاش‌های ناموفق ورود |
| **تنظیمات Portal** | Documentation page published/unpublished، Portal settings changed |

هر رکورد ممیزی موارد زیر را ثبت می‌کند:
- **تاریخ و زمان** (UTC)
- **Actor** — نام کاربری یا API token که اقدام را انجام داده
- **نوع رویداد** — اقدام خاص انجام‌شده
- **هدف** — کدام API، Plan، Application یا resource تحت تأثیر قرار گرفته
- **Patch** — تفاوت قبل/بعد پیکربندی تغییریافته (برای اکثر رویدادها در دسترس است)

---

### ۵.۲ دسترسی به گزارش‌های ممیزی و فیلتر کردن آن‌ها

#### گزارش‌های ممیزی در سطح پلتفرم

1. داشبورد ← نوار کناری چپ ← **Settings** ← **Audit**.
2. جدول ممیزی تمام رویدادها در همه APIها و applicationها را به ترتیب جدیدترین نشان می‌دهد.

**گزینه‌های فیلتر:**

| فیلتر | نحوه استفاده |
|---|---|
| **Date range** | تاریخ شروع و پایان را برای محدود کردن بازه تنظیم کنید |
| **Event** | یک نوع رویداد خاص از dropdown انتخاب کنید (مثلاً `API_UPDATED`، `SUBSCRIPTION_CREATED`) |
| **Environment** | در صورت اجرای چندین محیط، بر اساس محیط فیلتر کنید (مثلاً `staging`، `production`) |
| **Actor** | نام کاربری را تایپ کنید تا همه اقدامات یک مهندس یا service account خاص را ببینید |

3. روی هر ردیف کلیک کنید تا **نمای جزئیات** باز شود که full JSON patch را نشان می‌دهد (تفاوت قبل/بعد).

#### گزارش‌های ممیزی در سطح API

1. داشبورد ← **APIs** ← هر API را باز کنید ← نوار کناری چپ ← **Audit**.
2. همان کنترل‌های فیلتر اعمال می‌شوند، اما نتایج فقط به آن API خاص محدود می‌شوند.

> از ممیزی در سطح API هنگام بررسی یک حادثه روی یک سرویس خاص استفاده کنید (مثلاً «چه کسی JWT policy روی `service-a` بین ساعت ۱۴:۰۰ و ۱۶:۰۰ دیروز تغییر داد؟»).

---

### ۵.۳ تحلیل در سطح API

**هدف:** درک الگوهای ترافیک، نرخ خطا و رفتار مصرف‌کننده برای یک API خاص.

1. داشبورد ← **APIs** ← API خود را باز کنید ← نوار کناری چپ ← **Analytics**.
2. **date range** را تنظیم کنید (date picker بالا-راست) — گزینه‌ها شامل آخرین ساعت، آخرین ۲۴ ساعت، آخرین ۷ روز، بازه سفارشی است.

نمای Analytics شامل پنل‌های زیر است:

#### مرور کلی ترافیک

| معیار | توضیح |
|---|---|
| **Requests/sec** | نرخ درخواست در بازه انتخاب‌شده |
| **Total Hits** | تعداد مطلق درخواست‌ها |
| **Failed Requests** | درخواست‌هایی که منجر به پاسخ ۴xx یا ۵xx شدند |
| **Success Rate** | درصد پاسخ‌های ۲xx |
| **Average Latency** | زمان پاسخ end-to-end (دریافت Gateway ← پاسخ به کلاینت) |
| **Response Time Breakdown** | زمان پردازش Gateway در مقابل زمان پاسخ backend |

#### توزیع کد وضعیت

یک نمودار bar یا pie که نسبت پاسخ‌های `2xx`، `4xx` و `5xx` را نشان می‌دهد. از این برای شناسایی سریع افزایش ناگهانی خطا استفاده کنید.

- بالا بودن `401` / `403` ← مشکل احراز هویت یا مجوز (JWT plan یا پیکربندی API Key را بررسی کنید).
- بالا بودن `429` ← rate limiting در حال فعال شدن است — تنظیمات quota را مرور کنید (بخش ۳.۱).
- بالا بودن `502` / `503` ← backend خاموش است یا endpoint اشتباه پیکربندی شده.

#### Top Paths

پرفراخوانی‌ترین path‌های این API را نشان می‌دهد. برای شناسایی نقاط داغ و الگوهای سوءاستفاده مفید است.

1. داشبورد ← **APIs** ← API شما ← **Analytics** ← به **Top paths** اسکرول کنید.
2. روی هر path کلیک کنید تا به تعداد درخواست و نرخ خطای خاص آن بروید.

#### Top Consumers

Applicationها یا API Keyهایی که بیشترین ترافیک را ایجاد می‌کنند را فهرست می‌کند.

1. داشبورد ← **APIs** ← API شما ← **Analytics** ← **Top applications**.
2. مصرف‌کنندگانی که به rate limit خود نزدیک می‌شوند یا از آن تجاوز می‌کنند را شناسایی کنید.

---

### ۵.۴ تحلیل در سطح پلتفرم

**هدف:** دریافت یک نمای cross-API از ترافیک Gateway — مفید برای برنامه‌ریزی ظرفیت و شناسایی ناهنجاری‌ها در همه سرویس‌ها.

1. داشبورد ← نوار کناری چپ ← **Analytics** (آیتم سطح بالا، نه داخل یک API).
2. داشبورد پلتفرم معیارهای انباشته در همه APIها در محیط انتخاب‌شده را نشان می‌دهد.

پنل‌های کلیدی در این سطح:

| پنل | چه چیزی نشان می‌دهد |
|---|---|
| **Requests over time** | کل ترافیک Gateway در همه APIها |
| **Top APIs** | فهرست رتبه‌بندی‌شده APIها بر اساس حجم درخواست |
| **Top Applications** | فهرست رتبه‌بندی‌شده applicationهای مصرف‌کننده بر اساس ترافیک |
| **Response status distribution** | توزیع کلی ۲xx / ۴xx / ۵xx |
| **Average response time** | میانگین latency در همه APIها |
| **Top Failed APIs** | APIهایی با بالاترین نرخ خطا — برای بررسی اولویت‌بندی کنید |

**برای مقایسه دو API در کنار هم:**

1. Platform Analytics ← جدول **Top APIs** ← روی اولین API کلیک کنید تا فیلتر شود.
2. از dropdown **API filter** برای اضافه کردن API دوم استفاده کنید.
3. هر دو حالا روی نمودار time-series همپوشانی دارند.

---

### ۵.۵ تحلیل فعالیت اشتراک و مصرف‌کننده

**هدف:** ردیابی اینکه کدام applicationها از کدام APIها استفاده می‌کنند و علامت‌گذاری رفتار غیرعادی اشتراک.

#### مشاهده همه اشتراک‌های یک API

1. داشبورد ← **APIs** ← API خود را باز کنید ← **Subscriptions**.
2. ستون‌های جدول: نام Application، Plan مشترک‌شده، Status، تاریخ ایجاد، API Key (ماسک‌شده).
3. بر اساس **Status** فیلتر کنید: `ACCEPTED`، `PENDING`، `PAUSED`، `CLOSED`.

#### مشاهده همه اشتراک‌های یک Application

1. داشبورد ← **Applications** ← Application را باز کنید ← **Subscriptions**.
2. هر API و Plan که این application به آن مشترک است را با API Key یا توکن فعلی نشان می‌دهد.

#### شناسایی و اقدام درباره اشتراک‌های غیرفعال

1. داشبورد ← **APIs** ← API شما ← **Analytics** ← **Top applications**.
2. Applicationهایی که در پنجره analytics ظاهر نمی‌شوند در آن دوره ترافیک صفر داشته‌اند.
3. با **Subscriptions** مقابله کنید ← توقف یا بستن اشتراک‌های کهنه را در نظر بگیرید.

**برای توقف یا بستن یک اشتراک:**

1. داشبورد ← **APIs** ← API شما ← **Subscriptions** ← اشتراک را پیدا کنید.
2. روی ردیف کلیک کنید ← **Pause** (موقت) یا **Close** (دائمی، دسترسی را فوری لغو می‌کند).

---

### ۵.۶ خروجی گرفتن از داده‌های ممیزی و تحلیل

#### خروجی CSV از Audit Logs

1. داشبورد ← **Settings** ← **Audit**.
2. فیلترهای خود را اعمال کنید (date range، نوع رویداد، actor).
3. روی **Export** (بالا-راست) کلیک کنید ← به‌عنوان `.csv` دانلود کنید.

CSV شامل موارد زیر است: timestamp، event، actor، نام API/resource، environment و raw patch JSON در یک ستون.

#### خروجی داده‌های Analytics

1. داشبورد ← **APIs** ← API شما ← **Analytics**.
2. date range و هر فیلتری را تنظیم کنید.
3. روی **Export** کلیک کنید ← به‌عنوان `.csv` دانلود کنید.

ستون‌های Analytics خروجی گرفته‌شده شامل: سطل تاریخ، تعداد درخواست، تعداد موفق، تعداد ناموفق، میانگین latency (ms)، حداقل latency، حداکثر latency، p50، p95، p99 است.

> خروجی داخلی برای تحلیل موردی در ابزارهای spreadsheet مناسب است. برای ingestion مداوم در pipeline، از log forwarding استفاده کنید (بخش ۵.۷).

---

### ۵.۷ ارسال گزارش‌ها به سیستم‌های خارجی

برای تیم‌هایی که به داده‌های ممیزی و analytics در یک سیستم مدیریت log مرکزی (مثلاً Elasticsearch، Datadog، Splunk) نیاز دارند، Gravitee از log reporters در سطح Gateway پشتیبانی می‌کند.

#### فعال‌سازی Elasticsearch Reporter

این در فایل پیکربندی `gravitee.yml` **Gateway** (خارج از داشبورد) تنظیم می‌شود:

```yaml
reporters:
  elasticsearch:
    enabled: true
    endpoints:
      - http://elasticsearch.internal:9200
    index: gravitee
    bulk:
      actions: 1000
      flush_interval: 1
    security:
      username: elastic
      password: <password>
```

پس از فعال شدن reporter، Gateway داده‌های زیر را به‌صورت near real-time به Elasticsearch push می‌کند:

| الگوی Index | محتوا |
|---|---|
| `gravitee-request-*` | یک document به ازای هر درخواست API: path، method، status، latency، consumer، نام API |
| `gravitee-monitor-*` | معیارهای سلامت Gateway: JVM، CPU، thread pools |
| `gravitee-log-*` | گزارش‌های کامل body درخواست/پاسخ (اگر body logging برای API فعال باشد) |

#### فعال‌سازی Request Body Logging به ازای هر API

> ⚠️ این را فقط برای debugging فعال کنید. body logging هزینه عملکرد دارد و ممکن است داده‌های حساس را ثبت کند.

1. داشبورد ← **APIs** ← API خود را باز کنید ← **Settings** ← **Logging**.
2. **Logging** را روی `ON` قرار دهید.
3. پیکربندی کنید:
   - **Mode:** `CLIENT_PROXY` (هم درخواست کلاینت و هم آنچه به backend ارسال شده را ثبت می‌کند)
   - **Content:** `HEADERS_AND_PAYLOAD`
   - **Condition:** به‌صورت اختیاری به کدهای وضعیت خاص محدود کنید، مثلاً `{#response.status >= 500}`
4. **Save** ← **Deploy**.

گزارش‌ها در داشبورد ← **APIs** ← API شما ← **Logs** و در index Elasticsearch به نام `gravitee-log-*` ظاهر می‌شوند.

---

## ۶. ویژگی‌ها و گزینه‌های مستندسازی

Gravitee یک سیستم مستندسازی غنی داخل Developer Portal دارد. هر API می‌تواند مستندات مخصوص به خود داشته باشد و Portal تنها جایی است که مصرف‌کنندگان APIها را کشف، مطالعه و به آن‌ها مشترک می‌شوند. این بخش هر ویژگی مستندسازی موجود و نحوه استفاده از هر کدام را پوشش می‌دهد.

---

### ۶.۱ انواع صفحات مستندات

هنگام افزودن مستندات به یک API یا Portal، یک **نوع صفحه** انتخاب می‌کنید. هر کدام برای هدف متفاوتی مناسب است:

| نوع صفحه | بهترین کاربرد | نمایش به‌صورت |
|---|---|---|
| **Markdown** | مستندات روایی، راهنماها، changelogها، how-toها | HTML استایل‌دار در Portal |
| **OpenAPI (Swagger)** | قرارداد REST API: endpointها، schemaها، نمونه‌های درخواست/پاسخ | Swagger UI یا Redoc تعاملی |
| **AsyncAPI** | قرارداد API event-driven: channelها، messageها، bindingها | AsyncAPI rendered spec |
| **AsciiDoc** | مستندات فنی با قالب‌بندی پیشرفته | HTML استایل‌دار |
| **Link** | میانبر به یک URL خارجی (مثلاً صفحه Confluence، collection Postman) | لینک قابل کلیک در نوار کناری Portal |
| **Folder** | گروه‌بندی صفحات مرتبط زیر یک heading قابل جمع‌شدن | فقط بخش navigation |

**برای افزودن هر نوع صفحه:**

1. داشبورد ← **APIs** ← API خود را باز کنید ← **Documentation** ← **+ Add page**.
2. نوع صفحه را انتخاب کنید.
3. **Name** (به‌عنوان label نوار کناری استفاده می‌شود) و محتوا یا منبع را پر کنید.
4. **Published** را برای کنترل نمایش در Portal toggle کنید.
5. **Save**.

---

### ۶.۲ منابع مستندات

برای هر صفحه (صرف‌نظر از نوع)، انتخاب می‌کنید محتوا از کجا می‌آید:

#### Inline Editor

محتوا را مستقیماً در ویرایشگر داخلی داشبورد تایپ یا paste کنید.

- بهترین کاربرد: صفحات Markdown کوچک، یادداشت‌های سریع، changelogها.
- تغییرات فوراً ذخیره می‌شوند. **Published** را برای کنترل نمایش toggle کنید.

#### File Upload

یک فایل محلی `.md`، `.yaml`، `.adoc` یا `.json` آپلود کنید.

1. **+ Add page** ← نوع را انتخاب کنید ← **Source: File** ← فایل را آپلود کنید.
2. محتوا در Gravitee ذخیره می‌شود و دوباره fetch نمی‌شود. برای به‌روزرسانی، یک فایل جدید آپلود کنید.

#### External URL

محتوا را از یک URL عمومی قابل دسترسی در زمان render دریافت کنید.

1. **Source: URL** ← URL را وارد کنید (مثلاً `https://raw.githubusercontent.com/company/service-a/main/docs/api.yaml`).
2. **Fetch interval** را پیکربندی کنید (مثلاً هر ۱ ساعت) تا محتوا تازه بماند.
3. Gravitee URL را طبق زمان‌بندی تنظیم‌شده fetch کرده و نتیجه را cache می‌کند.

> بهترین کاربرد: OpenAPI specs که توسط backend شما ارائه می‌شوند (`/v3/api-docs`) یا در یک repository عمومی نگهداری می‌شوند.

#### GitHub / GitLab

مستندات را مستقیماً از یک branch مخزن Git همگام‌سازی کنید. در بخش ۶.۷ با جزئیات توضیح داده شده.

---

### ۶.۳ سازماندهی مستندات با پوشه‌ها

از صفحات **Folder** برای گروه‌بندی مستندات مرتبط زیر بخش‌های قابل جمع‌شدن در نوار کناری Portal استفاده کنید.

**ایجاد یک پوشه:**

1. داشبورد ← **APIs** ← API شما ← **Documentation** ← **+ Add page** ← **Folder**.
2. **Name:** مثلاً `Getting Started`
3. **Save**.

**جابجا کردن صفحات به داخل پوشه:**

1. در فهرست مستندات، صفحه را زیر پوشه بکشید **یا** صفحه را ویرایش کنید ← **Parent** را به نام پوشه تنظیم کنید.
2. پوشه به‌عنوان یک heading قابل جمع‌شدن در Portal ظاهر می‌شود. صفحات داخل آن به‌عنوان sub-item ظاهر می‌شوند.

**ساختار پوشه توصیه‌شده برای یک API production:**

```
📁 شروع کار
   ├── مرور کلی              (Markdown)
   ├── راهنمای احراز هویت   (Markdown)
   └── شروع سریع             (Markdown)
📁 مرجع API
   └── مشخصات OpenAPI        (OpenAPI)
📁 راهنماها
   ├── Rate Limiting          (Markdown)
   └── کدهای خطا             (Markdown)
📄 Changelog                  (Markdown)
🔗 Postman Collection         (Link)
```

---

### ۶.۴ مدیریت دید و دسترسی

هر صفحه مستندات دارای کنترل‌های نمایش مستقل است.

| تنظیم | رفتار |
|---|---|
| **Published: ON** | صفحه در Developer Portal برای هر کسی که می‌تواند API را ببیند نمایان است |
| **Published: OFF** | صفحه در داشبورد وجود دارد اما از Portal پنهان است — مفید برای pیش‌نویس‌ها |
| **Private: ON** | صفحه فقط برای کاربرانی که وارد Portal شده‌اند نمایان است (نه بازدیدکنندگان ناشناس) |
| **Private: OFF** | صفحه برای کاربران ناشناس Portal نمایان است (اگر API خود عمومی باشد) |

**برای تنظیم نمایش روی یک صفحه:**

1. داشبورد ← **APIs** ← API شما ← **Documentation** ← روی ردیف صفحه کلیک کنید.
2. **Published** و **Private** را بر اساس نیاز toggle کنید.
3. **Save**.

**کنترل نمایش Portal در سطح API:**

مستندات یک API فقط در صورتی قابل دسترسی است که خود API نمایان باشد. این را در اینجا تنظیم کنید:

1. داشبورد ← **APIs** ← API شما ← **Settings** ← **General**.
2. **Visibility:** `PUBLIC` (برای همه کاربران Portal شامل ناشناس نمایان است) یا `PRIVATE` (فقط برای اعضای Portal با دسترسی صریح نمایان است).

---

### ۶.۵ متادیتا و دسته‌بندی API

متادیتا APIها را در Developer Portal قابل کشف می‌کند و به مصرف‌کنندگان کمک می‌کند API مناسب را پیدا کنند.

#### تنظیم متادیتای API

1. داشبورد ← **APIs** ← API خود را باز کنید ← **Settings** ← **General**.
2. پر کنید:

   | فیلد | هدف | مثال |
   |---|---|---|
   | **Name** | نام نمایشی در Portal | `Service A — Resource API` |
   | **Version** | کنار نام نشان داده می‌شود | `2.1.0` |
   | **Description** | خلاصه کوتاه نشان داده‌شده در کارت‌های API | `Provides access to core resource data` |
   | **Labels** | تگ‌های آزاد برای فیلتر کردن | `internal`، `v2`، `deprecated` |
   | **Categories** | گروه‌بندی‌های کیوریت‌شده (تعریف‌شده در Portal Settings) | `Data`، `Internal`، `Partner` |
   | **Image / Logo** | در کارت‌های API Portal نشان داده می‌شود | یک PNG 200×200px آپلود کنید |

3. **Save** ← **Deploy**.

#### ایجاد Categories (ادمین)

1. داشبورد ← **Settings** ← **Categories** ← **+ Add category**.
2. **Name:** مثلاً `Internal Services`
3. **Description** و تصویر اختیاری.
4. **Save**.
5. APIها را از طریق فیلد **Settings → General → Categories** API به این category اختصاص دهید.

#### افزودن فیلدهای متادیتای سفارشی

برای فیلدهایی که توسط پیش‌فرض‌ها پوشش داده نشده‌اند (مثلاً `team-owner`، `SLA`، `data-classification`):

1. داشبورد ← **APIs** ← API شما ← **Metadata** ← **+ Add metadata**.
2. **Name:** `team-owner`
3. **Value:** `platform-team`
4. **Format:** `STRING` (یا `NUMERIC`، `BOOLEAN`، `DATE`، `URL`)
5. **Save**.

متادیتای سفارشی در Portal نمایان است و از طریق Management API قابل بازیابی است.

---

### ۶.۶ پیوست مستندات به پلن‌ها

می‌توانید یک صفحه مستندات خاص را به یک Plan متصل کنید تا مشترکین دستورالعمل‌های مخصوص plan را ببینند (مثلاً راهنماهای متفاوت برای مصرف‌کنندگان API Key در مقابل JWT).

1. داشبورد ← **APIs** ← API شما ← **Plans** ← یک plan را ویرایش کنید.
2. در ویرایشگر plan ← تب **General** ← بخش **Characteristics**.
3. **Documentation page:** صفحه‌ای را از dropdown برای پیوست انتخاب کنید.
4. **Save** ← **Deploy**.

صفحه پیوندشده در Portal روی نمای جزئیات Plan نمایان می‌شود و قبل از اشتراک برای مصرف‌کنندگان قابل مشاهده است.

---

### ۶.۷ همگام‌سازی مستندات از Git

**هدف:** نگه داشتن مستندات به‌صورت خودکار همگام با فایل‌های commit‌شده به مخزن Git شما. هنگامی که repo تغییر می‌کند، Portal به‌روز می‌شود.

**مرحله ۱ — پیکربندی Git fetcher (ادمین):**

1. داشبورد ← **Settings** ← **Documentation** ← **Fetchers**.
2. روی **+ Add fetcher** کلیک کنید ← **GitHub** یا **GitLab**.
3. پر کنید:
   - **Name:** `service-a-docs-github`
   - **GitHub API URL:** `https://api.github.com` (یا URL GitHub Enterprise شما)
   - **Repository:** `company/service-a`
   - **Branch:** `main`
   - **Personal Access Token:** `<github-pat-with-repo-read-scope>`
4. **Save**.

**مرحله ۲ — پیوند یک صفحه مستندات به fetcher:**

1. داشبورد ← **APIs** ← API شما ← **Documentation** ← **+ Add page** ← **Markdown**.
2. **Source:** **GitHub** (یا **GitLab**) را انتخاب کنید.
3. fetcher پیکربندی‌شده در بالا را انتخاب کنید.
4. **File path in repo:** `docs/getting-started.md`
5. **Auto-fetch:** ON ← interval را تنظیم کنید (مثلاً `1 HOURS`).
6. **Published** را روی ON قرار دهید.
7. **Save**.

هنگامی که فایل در `docs/getting-started.md` در branch `main` به‌روز می‌شود، Gravitee در interval زمان‌بندی‌شده بعدی آن را fetch کرده و صفحه Portal را به‌طور خودکار به‌روز می‌کند.

**همگام‌سازی یک پوشه کامل از Git:**

1. **+ Add page** ← نوع **Folder** ← **Source: GitHub**.
2. **Directory path in repo:** `docs/` (دایرکتوری، نه یک فایل واحد).
3. Gravitee همه فایل‌های Markdown و OpenAPI در آن دایرکتوری را به‌عنوان صفحات جداگانه زیر پوشه وارد می‌کند.

---

### ۶.۸ مرجع کامل گزینه‌های مستندسازی

مرجع کامل هر گزینه قابل پیکربندی روی یک صفحه مستندات.

| گزینه | مقادیر | توضیح |
|---|---|---|
| **Name** | متن آزاد | label نوار کناری و عنوان صفحه در Portal |
| **Type** | `MARKDOWN`، `OPENAPI`، `ASYNCAPI`، `ASCIIDOC`، `LINK`، `FOLDER` | کنترل می‌کند محتوا چگونه render شود |
| **Source** | `INLINE`، `FILE`، `URL`، `GITHUB`، `GITLAB` | محل fetch شدن محتوا |
| **Published** | `ON` / `OFF` | هنگام ON در Portal نمایان است |
| **Private** | `ON` / `OFF` | هنگام ON نیاز به ورود به Portal دارد |
| **Order** | عدد صحیح | موقعیت مرتب‌سازی داخل پوشه parent یا root را کنترل می‌کند |
| **Parent** | نام صفحه Folder | این صفحه را داخل یک پوشه جای می‌دهد |
| **Homepage** | `ON` / `OFF` | این صفحه را به‌عنوان صفحه فرود پیش‌فرض API در Portal تنظیم می‌کند |
| **Auto-fetch** | `ON` / `OFF` | طبق یک زمان‌بندی از URL یا منبع Git دوباره fetch می‌کند |
| **Fetch interval** | عدد صحیح + واحد | هر چند وقت یک بار re-fetch کند (مثلاً `1 HOURS`، `30 MINUTES`) |
| **Content-type override** | مثلاً `application/json` | یک MIME type خاص برای محتوای از URL اجباری می‌کند |
| **Characteristics (Plan link)** | نام Plan | این صفحه را با یک Plan خاص مرتبط می‌کند |
| **Try-it enabled** | `ON` / `OFF` | دکمه «Try it» را روی صفحات OpenAPI نشان می‌دهد |
| **Try-it URL** | URL | URL پایه استفاده‌شده توسط ویژگی try-it در Swagger UI (پیش‌فرض entrypoint Gateway است) |
| **Show URL** | `ON` / `OFF` | URL منبع را روی صفحه Portal نشان می‌دهد (برای نوع Link) |
| **OpenAPI display** | `Swagger UI` / `Redoc` | renderer مورد استفاده برای صفحات OpenAPI |
| **Access Control** | نام گروه‌ها | نمایش صفحه را به گروه‌های کاربری Portal خاص محدود می‌کند |

---

*نسخه سند: 2.0 | Gravitee 4.x | آخرین به‌روزرسانی: 2026*
