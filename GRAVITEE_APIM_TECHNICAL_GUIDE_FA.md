# راهنمای فنی Gravitee API Management — (نسخه Self-Managed / Community Edition)

> این مستند معماری بک‌اند، ساختار پایگاه داده، نحوه دیباگ سورس‌کد و اندپوینت‌های اصلی Management API را پوشش می‌دهد. مخاطب این مستند تیم‌هایی هستند که Gravitee را به صورت Self-Managed میزبانی می‌کنند و ویژگی‌های Enterprise در آن لحاظ نشده است.

---

## فهرست مطالب

1. [معماری سیستم](#1-معماری-سیستم)
2. [ساختار پایگاه داده](#2-ساختار-پایگاه-داده)
3. [دیباگ سورس‌کد](#3-دیباگ-سورس‌کد)
4. [اندپوینت‌های Management API](#4-اندپوینت‌های-management-api)

---

## 1. معماری سیستم

### 1.1 نمای کلی

Gravitee APIM یک مونوریپو (monorepo) مبتنی بر **Apache Maven** است. پلتفرم شامل دو سرویس بک‌اند اصلی است — **Management API** و **Gateway** — که لایه داده و سیستم پلاگین مشترکی دارند.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     کلاینت‌ها / مصرف‌کنندگان                        │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    API Gateway (Vert.x)                             │
│   دریافت ترافیک API، اعمال پالیسی‌ها، مسیریابی به بک‌اندها        │
│   پورت: 8082                                                       │
└──────────┬──────────────────────────────────┬───────────────────────┘
           │ خواندن تعاریف API                │ ارسال آنالیتیکس
           ▼                                  ▼
┌─────────────────────┐           ┌───────────────────────┐
│     MongoDB         │           │    Elasticsearch      │
│  (داده‌های مدیریتی) │           │  (آنالیتیکس و لاگ‌ها) │
└─────────┬───────────┘           └───────────────────────┘
          │ CRUD
          ▼
┌─────────────────────────────────────────────────────────────────────┐
│             Management API (Jetty / JAX-RS)                        │
│   سرویس‌دهی به Console UI، Portal UI و ادغام‌های خارجی            │
│   پورت: 8083                                                       │
└──────────┬──────────────────────────────────┬───────────────────────┘
           │                                  │
           ▼                                  ▼
┌─────────────────────┐           ┌───────────────────────┐
│    Console UI        │           │   Developer Portal    │
│    (Angular)         │           │    (Angular)          │
│    پورت: 8084       │           │    پورت: 8085         │
└─────────────────────┘           └───────────────────────┘
```

### 1.2 سرویس‌های بک‌اند

| سرویس | تکنولوژی | پورت | وظیفه |
|--------|----------|------|-------|
| **Gateway** | Vert.x 4.x + RxJava 3 | 8082 | دریافت ترافیک API، اجرای زنجیره پالیسی‌ها، پراکسی به بک‌اندها، گزارش آنالیتیکس |
| **Management API** | Spring Boot 3.x + Jetty + JAX-RS (Jersey) | 8083 | REST API برای مدیریت APIها، اپلیکیشن‌ها، کاربران و تنظیمات. هر دو Console و Portal API را سرویس‌دهی می‌کند |

### 1.3 ماژول‌های سطح بالا

| ماژول | وظیفه |
|-------|-------|
| `gravitee-apim-gateway` | زمان اجرای Gateway — reactor، موتور پالیسی، کانکتورها، هندلرهای HTTP/TCP |
| `gravitee-apim-rest-api` | Management API — کنترلرهای REST، منطق تجاری، سرویس‌های پس‌زمینه |
| `gravitee-apim-definition` | مدل‌های مشترک تعریف API (نسخه v2 و v4) و سریالایز Jackson |
| `gravitee-apim-repository` | لایه دسترسی به داده — اینترفیس‌ها + پیاده‌سازی‌ها برای MongoDB، JDBC، Elasticsearch، Redis |
| `gravitee-apim-plugin` | سیستم پلاگین — endpointها، entrypointها، سرویس‌های API، reactor handlerها |
| `gravitee-apim-common` | ابزارهای مشترک و MapStruct mapperها |
| `gravitee-apim-distribution` | بسته‌بندی و اسمبلی برای توزیع |

### 1.4 معماری Gateway

گیت‌وی یک runtime واکنشی (reactive) و غیرمسدودکننده (non-blocking) مبتنی بر Vert.x است. ساب‌ماژول‌های اصلی:

| ساب‌ماژول | نقش |
|-----------|-----|
| `gateway-reactor` | توزیع درخواست‌ها — تطبیق درخواست‌های ورودی با هندلرهای API از طریق acceptor resolver |
| `gateway-core` | کانتکست اجرا، مدیریت اتصال، failover، پشتیبانی V4 |
| `gateway-handlers` | هندلرهای سطح API (`ApiReactorHandler`) و گروه‌های پالیسی مشترک |
| `gateway-policy` | موتور اجرای پالیسی — زنجیره‌بندی پالیسی‌ها به ترتیب request/response |
| `gateway-flow` | رفع flow — ارزیابی شرایط برای انتخاب flowهای مناسب |
| `gateway-http` / `gateway-tcp` | هندلرهای اختصاصی پروتکل |
| `gateway-services` | سرویس‌های پس‌زمینه — همگام‌سازی، health check، گزارش‌دهی، زمان‌بندی |
| `gateway-reporting` | گزارش متریکس و آنالیتیکس به Elasticsearch |
| `gateway-opentelemetry` | ادغام با OpenTelemetry برای ردیابی توزیع‌شده |

**مسیر پردازش درخواست:**

```
درخواست HTTP → سرور Vert.x
  → DefaultHttpRequestDispatcher
    → پردازشگرهای پلتفرم (متریکس، شناسه تراکنش، ردیابی)
      → رفع Acceptor (تطبیق مسیر با API)
        → API Reactor (V2/V3: SyncApiReactor | V4: DefaultApiReactor)
          → زنجیره امنیت (اعتبارسنجی API Key، OAuth2، JWT)
            → زنجیره پالیسی درخواست (تبدیل، محدودیت نرخ، کش، و...)
              → فراخوانی Endpoint (پراکسی HTTP، Mock، پراکسی TCP)
            → زنجیره پالیسی پاسخ
          → پردازشگر گزارش‌دهی (آنالیتیکس → Elasticsearch)
        → پاسخ HTTP → کلاینت
```

### 1.5 معماری Management API

Management API از معماری لایه‌ای پیروی می‌کند:

| لایه | ماژول‌ها | نقش |
|------|---------|-----|
| **REST** | `rest-api-management` (v1)، `rest-api-management-v2` (v2)، `rest-api-portal` | کلاس‌های JAX-RS resource — پارس درخواست، نگاشت پاسخ |
| **Security** | `rest-api-security` | فیلترهای احراز هویت (`SecurityContextFilter`) و مجوزدهی (`PermissionsFilter`) |
| **Service** | `rest-api-service` | منطق تجاری، اعتبارسنجی، انتشار رویداد |
| **Background Services** | `rest-api-services` | کارهای زمان‌بندی‌شده — ممیزی، واکشی خودکار، همگام‌سازی دیکشنری، ایندکس‌گذاری جستجو، اعلان‌های اشتراک، همگام‌سازی Gateway |
| **Repository** | `rest-api-repository` → `gravitee-apim-repository` | دسترسی به داده از طریق اینترفیس‌های repository |

**مسیر پردازش درخواست:**

```
درخواست REST → سرور Jetty
  → SecurityContextFilter (اعتبارسنجی JWT/توکن)
    → PermissionsFilter (بررسی انوتیشن @Permission)
      → متد JAX-RS Resource
        → لایه Service (منطق تجاری + @Transactional)
          → EventService (انتشار رویدادهای دامنه)
          → لایه Repository (عملیات CRUD در MongoDB/JDBC)
        → DTO پاسخ → JSON
      → ExceptionMapper (در صورت خطا)
    → پاسخ HTTP
```

### 1.6 ارتباط بین سرویس‌ها

Gateway و Management API از طریق **پایگاه داده مشترک + رویدادها** ارتباط برقرار می‌کنند، نه فراخوانی مستقیم HTTP:

1. Management API تعاریف API را در MongoDB ذخیره و یک رویداد (مثلاً `API_DEPLOY`) منتشر می‌کند
2. **SyncService** در Gateway هر ۵ ثانیه یک‌بار (`*/5 * * * * *`) ریپازیتوری را بررسی می‌کند
3. Gateway تعاریف API به‌روزشده را در حافظه داخلی خود بارگذاری می‌کند
4. نمونه‌های جدید `ApiReactorHandler` برای APIهای تغییر یافته ایجاد/به‌روز می‌شوند

برای Gatewayهای کلاستری، از **Redis** برای همگام‌سازی رویدادهای توزیع‌شده و هماهنگی وضعیت sync استفاده می‌شود.

### 1.7 سیستم پلاگین

Gravitee از طریق پلاگین‌ها بسیار قابل توسعه است. ماژول `gravitee-apim-plugin` شامل:

| نوع پلاگین | مثال‌ها | وظیفه |
|------------|--------|-------|
| **Endpoint** | `endpoint-http-proxy`، `endpoint-mock`، `endpoint-tcp-proxy` | اهداف اتصال به بک‌اند |
| **Entrypoint** | `entrypoint-http-proxy`، `entrypoint-tcp-proxy` | پروتکل‌های ورودی API سمت کلاینت |
| **API Service** | `apiservice-dynamicproperties`، `apiservice-healthcheck-http`، `apiservice-servicediscovery-consul` | سرویس‌های پس‌زمینه متصل به APIها |
| **Reactor** | پلاگین‌های reactor مبتنی بر پیام | پیاده‌سازی‌های سفارشی reactor |

پلاگین‌ها از مسیرهای `$GRAVITEE_HOME/plugins` و `$GRAVITEE_HOME/plugins-ext` در هنگام راه‌اندازی بارگذاری می‌شوند.

---

## 2. ساختار پایگاه داده

### 2.1 نمای کلی

Gravitee از سه بک‌اند ذخیره‌سازی استفاده می‌کند:

| بک‌اند | وظیفه | ضروری |
|--------|-------|-------|
| **MongoDB** (یا JDBC) | تمام داده‌های مدیریتی — APIها، اپلیکیشن‌ها، کاربران، پلن‌ها، اشتراک‌ها، تنظیمات | بله |
| **Elasticsearch** | آنالیتیکس، لاگ درخواست‌ها، health check، متریکس V4 | بله |
| **Redis** | محدودیت نرخ، همگام‌سازی رویداد توزیع‌شده، وضعیت کلاستر | اختیاری (برای Gateway چند نودی لازم است) |

### 2.2 کالکشن‌های MongoDB (نمای منطقی)

نام کالکشن‌ها از پیشوند قابل تنظیم استفاده می‌کنند (پیش‌فرض: بدون پیشوند). گروه‌بندی بر اساس دامنه:

#### مدیریت اصلی API

| کالکشن | وظیفه | روابط کلیدی |
|--------|-------|-------------|
| `apis` | تعاریف API — نسخه، پیکربندی، وضعیت چرخه حیات، قابلیت مشاهده | شامل ارجاع به پلن‌ها |
| `plans` | پلن‌های API — نوع امنیت، سهمیه‌ها، محدودیت نرخ، حالت اعتبارسنجی | متعلق به یک API |
| `subscriptions` | اشتراک اپلیکیشن به API از طریق یک پلن | اتصال اپلیکیشن → پلن → API |
| `keys` | کلیدهای API صادر شده برای اشتراک‌ها | متعلق به یک اشتراک |
| `flows` | تعاریف flow پالیسی درخواست/پاسخ | متصل به APIها یا پلتفرم |

#### اپلیکیشن‌ها

| کالکشن | وظیفه |
|--------|-------|
| `applications` | اپلیکیشن‌های مصرف‌کننده که به APIها اشتراک می‌گیرند |

#### کاربران، گروه‌ها و دسترسی

| کالکشن | وظیفه |
|--------|-------|
| `users` | حساب‌های کاربری (ایمیل/رمز عبور رمزنگاری‌شده) |
| `roles` | تعاریف نقش با مجموعه مجوزها |
| `groups` | گروه‌های کاربری |
| `memberships` | عضویت کاربر در گروه |
| `identity_providers` | پیکربندی IdPهای خارجی (OIDC، LDAP) |
| `identity_provider_activations` | فعال‌سازی IdP به ازای هر محیط |
| `tokens` | توکن‌های دسترسی شخصی |
| `invitations` | دعوت‌نامه‌های کاربری |
| `custom_user_fields` | فیلدهای سفارشی پروفایل کاربر |

#### سازمان و محیط

| کالکشن | وظیفه |
|--------|-------|
| `organizations` | سلسله‌مراتب سازمان سطح بالا |
| `environments` | پیکربندی محیط‌ها در سازمان‌ها |
| `access_points` | پیکربندی نقاط دسترسی |
| `tenants` | پشتیبانی از چندمستأجری |
| `entrypoints` | تعاریف entrypoint گیت‌وی |
| `parameters` | پارامترها و تنظیمات سیستمی/عمومی |
| `installation` | متادیتای نصب |

#### محتوا و مستندات

| کالکشن | وظیفه |
|--------|-------|
| `pages` | صفحات مستندات/محتوا |
| `page_revisions` | تاریخچه نسخه‌های صفحه |
| `categories` | دسته‌بندی/تگ APIها |
| `tags` | تگ‌های sharding |
| `metadata` / `metadatas` | تعاریف و مقادیر متادیتا |
| `themes` | سفارشی‌سازی تم پورتال |
| `dashboards` | داشبوردهای سفارشی آنالیتیکس |
| `dictionaries` | دیکشنری‌های property پویا |

#### پورتال

| کالکشن | وظیفه |
|--------|-------|
| `portal_pages` | صفحات اختصاصی پورتال |
| `portal_page_contexts` | پیکربندی‌های کانتکست صفحه پورتال |
| `portal_page_contents` | ذخیره محتوای صفحه پورتال |
| `portal_navigation_items` | ساختار ناوبری پورتال |
| `portal_menu_links` | پیکربندی لینک‌های منوی پورتال |

#### اعلان‌ها و هشدارها

| کالکشن | وظیفه |
|--------|-------|
| `alert_triggers` | تعاریف تریگر هشدار |
| `alert_events` | نمونه‌های رویداد هشدار |
| `portalnotifications` | اعلان‌های پورتال |
| `portalnotificationconfigs` | ترجیحات اعلان پورتال |
| `genericnotificationconfigs` | پیکربندی‌های عمومی اعلان |
| `notificationTemplates` | قالب‌های ایمیل/پیام |

#### رویدادها، ممیزی و کارها

| کالکشن | وظیفه |
|--------|-------|
| `events` | رویدادهای سیستمی (استقرار API، شروع، توقف و...) |
| `events_latest` | آخرین رویداد به ازای هر موجودیت (بهینه‌سازی) |
| `audits` | گزارش کامل ممیزی تغییرات |
| `commands` | صف فرمان‌های ناهمزمان |
| `asyncjobs` | ردیابی کارهای ناهمزمان |

#### پالیسی‌ها و کیفیت

| کالکشن | وظیفه |
|--------|-------|
| `sharedpolicygroups` | تعاریف گروه پالیسی قابل استفاده مجدد |
| `sharedpolicygrouphistories` | تاریخچه نسخه‌های گروه پالیسی |
| `qualityrules` | تعاریف قواعد کیفیت |
| `apiqualityrules` | قواعد کیفیت اعمال‌شده بر APIهای خاص |

#### سایر

| کالکشن | وظیفه |
|--------|-------|
| `ratings` / `ratingAnswers` | امتیازدهی و نظرات API |
| `tickets` | تیکت‌های پشتیبانی |
| `workflows` | وضعیت گردش کار بازبینی API |
| `promotions` | ترفیع API بین محیط‌ها |
| `integrations` | پیکربندی‌های ادغام شخص ثالث |
| `client_registration_providers` | ثبت پویای کلاینت OIDC |
| `licenses` | اطلاعات لایسنس |
| `node_monitoring` | داده‌های مانیتورینگ نود Gateway |
| `upgrades` | ردیابی مایگریشن پایگاه داده |

### 2.3 روابط کلیدی موجودیت‌ها

```
Organization (سازمان)
  └── Environment (محیط)
        ├── API
        │     ├── Plan (پلن) (1:N)
        │     ├── Flow (1:N)
        │     ├── Page (مستندات) (1:N)
        │     └── Metadata (1:N)
        │
        ├── Application (اپلیکیشن)
        │     └── Subscription (اشتراک) → Plan → API
        │           └── API Key (کلید API) (1:N)
        │
        ├── User (کاربر)
        │     ├── Membership (عضویت) → Group (گروه)
        │     └── Role (نقش) (از طریق عضویت)
        │
        └── Configuration (پیکربندی)
              ├── Category, Tag, Dictionary
              ├── Identity Provider
              ├── Notification Templates
              └── Portal Theme
```

### 2.4 ایندکس‌های Elasticsearch

Elasticsearch داده‌های آنالیتیکس سری زمانی را ذخیره می‌کند. نام ایندکس‌ها از الگوی `{prefix}-{type}-{date}` پیروی می‌کنند (پیشوند پیش‌فرض: `gravitee`).

| نوع ایندکس | محتوا |
|------------|-------|
| `gravitee-request-*` | لاگ درخواست‌های API نسخه V2/V3 — تأخیر، وضعیت، مصرف‌کننده، API |
| `gravitee-health-check-*` | نتایج پروب health check و دسترس‌پذیری endpoint |
| `gravitee-monitor-*` | داده‌های مانیتورینگ نود Gateway |
| `gravitee-metrics-*` | متریکس API نسخه V4 — اتصالات، تعداد پیام‌ها |
| `gravitee-log-*` | لاگ‌های جزئی درخواست/پاسخ |
| `gravitee-message-log-*` | لاگ‌های پیام/رویداد V4 |
| `gravitee-message-metrics-*` | متریکس سطح پیام V4 |

از چندین استراتژی نام‌گذاری ایندکس پشتیبانی می‌شود: مبتنی بر ILM (چرخش روزانه/هفتگی)، به ازای هر نوع، و چند نوعی.

### 2.5 داده‌های Redis

در صورت اجرای چندین نود Gateway استفاده می‌شود:

| الگوی کلید | وظیفه |
|-----------|-------|
| `ratelimit:{subscriptionId}` | شمارنده‌های محدودیت نرخ به ازای هر اشتراک — شمارنده، سقف، زمان ریست |
| `distributed_event:{refType}:{refId}:{timestamp}` | همگام‌سازی رویداد توزیع‌شده بین نودهای Gateway |
| `distributed_sync_state:{clusterId}` | هش وضعیت همگام‌سازی کلاستر |

---

## 3. دیباگ سورس‌کد

### 3.1 سیستم بیلد

پروژه از **Maven 4.0.0** با پروفایل‌های بیلد برای کامپایل بخش‌های خاص استفاده می‌کند:

| پروفایل | ماژول‌های بیلد شده |
|---------|--------------------|
| `all-modules` (پیش‌فرض) | همه چیز |
| `main-modules` | Management API، Gateway، Definition، Common |
| `gateway-modules` | فقط Gateway |
| `rest-api-modules` | فقط Management API |
| `definition-modules` | فقط مدل‌های تعریف API |
| `plugin-modules` | زیرساخت پلاگین |

بیلد از ریشه:

```bash
mvn clean install -DskipTests                      # بیلد کامل
mvn clean install -P rest-api-modules -DskipTests  # فقط Management API
mvn clean install -P gateway-modules -DskipTests   # فقط Gateway
```

### 3.2 نقطه ورود Management API

**زنجیره بوت‌استرپ:**

```
Bootstrap.main()
  → GraviteeApisContainer (extends SpringBasedContainer)
    → StandaloneConfiguration (Spring @Configuration)
      → GraviteeManagementApplication (JAX-RS ResourceConfig)
        → ثبت: OrganizationsResource، SecurityContextFilter، PermissionsFilter، ExceptionMappers
```

**فایل‌های کلیدی:**

| فایل | وظیفه |
|------|-------|
| `rest-api-standalone-bootstrap/.../Bootstrap.java` | نقطه ورود اصلی. تنظیم `gravitee.home`، ایجاد classloaderها، راه‌اندازی container |
| `rest-api-standalone-container/.../GraviteeApisContainer.java` | بوت‌استرپ Spring Boot container |
| `rest-api-management-rest/.../GraviteeManagementApplication.java` | JAX-RS ResourceConfig — ثبت تمام REST resourceها، فیلترها، exception mapperها |
| `rest-api-standalone-distribution/.../config/gravitee.yml` | فایل پیکربندی اصلی |

**برای دیباگ در IDE**: اجرای `Bootstrap.main()` با آرگومان VM `-Dgravitee.home=/path/to/distribution`.

### 3.3 نقطه ورود Gateway

**زنجیره بوت‌استرپ:**

```
Bootstrap.main()
  → GatewayContainer (extends SpringBasedContainer)
    → StandaloneConfiguration (Spring @Configuration)
      → سرور HTTP Vert.x (پورت 8082)
        → DefaultHttpRequestDispatcher
```

**فایل‌های کلیدی:**

| فایل | وظیفه |
|------|-------|
| `gateway-standalone-bootstrap/.../Bootstrap.java` | نقطه ورود اصلی |
| `gateway-standalone-container/.../GatewayContainer.java` | Spring Boot container. همچنین دارای متد `main()` برای دیباگ در IDE |
| `gateway-standalone-distribution/.../config/gravitee.yml` | پیکربندی Gateway |

**برای دیباگ در IDE**: اجرای `GatewayContainer.main()` با `-Dgravitee.home=/path/to/distribution`.

### 3.4 گراف وابستگی ماژول‌ها

درک اینکه برای یک مشکل خاص کدام ماژول را باید بررسی کرد:

```
لایه REST (آنچه به عنوان اندپوینت مشاهده می‌کنید)
├── rest-api-management         ← کنترلرهای v1 زیر /management
├── rest-api-management-v2      ← کنترلرهای v2 زیر /v2
└── rest-api-portal             ← کنترلرهای پورتال زیر /portal
        │
        ▼
لایه Service (منطق تجاری)
├── rest-api-service            ← سرویس‌های CRUD، منطق دامنه، مبدل‌ها
├── rest-api-services           ← کارهای پس‌زمینه (sync، ممیزی، ایندکس‌گذاری و...)
└── rest-api-security           ← فیلترهای احراز هویت، بررسی مجوزها
        │
        ▼
لایه Data (ماندگاری)
├── rest-api-repository         ← انتزاع repository
└── gravitee-apim-repository    ← پیاده‌سازی‌ها:
    ├── repository-mongodb      ←   MongoDB
    ├── repository-jdbc         ←   PostgreSQL، MySQL، SQL Server
    ├── repository-elasticsearch ←  کوئری‌های آنالیتیکس
    └── repository-redis        ←   محدودیت نرخ، همگام‌سازی توزیع‌شده
```

### 3.5 نقاط کلیدی برای Breakpoint

| هدف دیباگ | محل قرار دادن Breakpoint |
|-----------|--------------------------|
| هر درخواست Management API | `SecurityContextFilter` — ردیابی زنجیره احراز هویت |
| مشکلات مجوز/اختیار | `PermissionsFilter` — بررسی انوتیشن‌های `@Permission` |
| عملیات CRUD روی API | `ApiService` (یا `ApiCrudServiceImpl`) در `rest-api-service` |
| پردازش درخواست Gateway | `ApiReactorHandler.doHandle()` — ورود به پردازش سطح API |
| اجرای پالیسی | متدهای execute/apply در `PolicyChain` |
| انتخاب Flow | `BestMatchFlowResolver` — ارزیابی شرایط برای انتخاب flowها |
| همگام‌سازی Gateway از management | `SyncService` در `gateway-services` — بررسی تغییرات تعاریف API |
| راه‌اندازی/بوت‌استرپ | `Bootstrap.main()` یا `GraviteeApisContainer.main()` / `GatewayContainer.main()` |

### 3.6 قراردادهای نام‌گذاری لایه Service

لایه سرویس از الگوی نام‌گذاری یکسانی استفاده می‌کند:

| الگو | وظیفه | مثال |
|------|-------|------|
| `*CrudService` | عملیات CRUD روی یک موجودیت | `ApiCrudService` |
| `*QueryService` | کوئری‌های فقط‌خواندنی، جستجو، فیلتر | `ApiQueryService` |
| `*DomainService` | منطق تجاری بین aggregateها | `ApiDomainService` |

### 3.7 پردازش API نسخه V2 در مقابل V4

Gateway دو مسیر پردازش موازی دارد:

| نسخه | Reactor | سبک |
|------|---------|-----|
| APIهای V2/V3 | `SyncApiReactor` | پراکسی همزمان — درخواست/پاسخ |
| APIهای V4 | `DefaultApiReactor` | واکنشی — پشتیبانی از الگوهای رویداد‌محور و مبتنی بر پیام |

کوالیفایرهای Spring آن‌ها را متمایز می‌کنند:
- `@Qualifier("v3AcceptorResolver")` / `@Qualifier("v4AcceptorResolver")`
- `@Qualifier("v3RequestProcessorChainFactory")` / `@Qualifier("v4RequestProcessorChainFactory")`

### 3.8 زیرساخت تست

| نوع تست | مسیر | فریم‌ورک |
|---------|------|---------|
| تست‌های واحد | `src/test/java` در هر ماژول | JUnit 5 + Mockito |
| تست‌های یکپارچگی | `gravitee-apim-integration-tests` | انوتیشن `@GatewayTest` + Wiremock + Awaitility |
| تست‌های E2E | `gravitee-apim-e2e` | سناریوهای انتها به انتها |
| تست‌های عملکرد | `gravitee-apim-perf` | تست بار |

تست‌های یکپارچگی Gateway از `@GatewayTest(v2ExecutionMode = ExecutionMode.V3)` برای مشخص کردن حالت نسخه API استفاده می‌کنند.

---

## 4. اندپوینت‌های Management API

Management API سه مجموعه اندپوینت REST ارائه می‌دهد:

| API | مسیر پایه | وظیفه | مصرف‌کنندگان |
|-----|-----------|-------|-------------|
| **Management v1** | `/management/organizations/{orgId}/environments/{envId}/...` | مدیریت کامل چرخه حیات API | Console UI، اسکریپت‌ها |
| **Management v2** | `/management/v2/...` | مدیریت API به سبک RESTful مدرن | Console UI، اتوماسیون |
| **Portal** | `/portal/environments/{envId}/...` | کشف و اشتراک API برای کاربران | UI پورتال توسعه‌دهنده |

### 4.1 Management API v1 — سطح سازمان

**پایه**: `/organizations/{orgId}`

| دسته | الگوی اندپوینت | متدها | توضیحات |
|------|----------------|-------|---------|
| **سازمان‌ها** | `/organizations` | GET, POST | لیست و ایجاد سازمان‌ها |
| **سازمان** | `/organizations/{orgId}` | GET, PUT | دریافت/به‌روزرسانی سازمان |
| **محیط‌ها** | `/{orgId}/environments` | GET, POST | لیست و ایجاد محیط‌ها |
| **کاربران** | `/{orgId}/users` | GET, POST | مدیریت کاربران |
| **کاربر جاری** | `/{orgId}/user` | GET, PUT | پروفایل، آواتار، وظایف، اعلان‌ها، توکن‌ها |
| **پیکربندی** | `/{orgId}/configuration` | GET | پیکربندی پلتفرم |
| **نقش‌ها** | `/{orgId}/configuration/rolescopes` | GET | تعاریف scope نقش |
| **ارائه‌دهندگان هویت** | `/{orgId}/configuration/identities` | GET, POST | مدیریت IdP |
| **قالب‌های اعلان** | `/{orgId}/configuration/notification-templates` | GET, PUT | قالب‌های ایمیل/پیام |

### 4.2 Management API v1 — سطح محیط

**پایه**: `/organizations/{orgId}/environments/{envId}`

#### مدیریت API

| الگوی اندپوینت | متدها | توضیحات |
|----------------|-------|---------|
| `/apis` | GET, POST | لیست، ایجاد، ایمپورت APIها |
| `/apis/{apiId}` | GET, PUT, DELETE | عملیات CRUD روی API |
| `/apis/{apiId}/deploy` | POST | استقرار API در Gateway |
| `/apis/{apiId}/state` | GET, POST | چرخه حیات API (شروع/توقف) |
| `/apis/{apiId}/plans` | GET, POST | مدیریت پلن |
| `/apis/{apiId}/plans/{planId}` | GET, PUT, DELETE | عملیات CRUD پلن خاص |
| `/apis/{apiId}/subscriptions` | GET, POST | مدیریت اشتراک |
| `/apis/{apiId}/members` | GET, POST, DELETE | اعضای تیم API |
| `/apis/{apiId}/metadata` | GET, POST | متادیتای API |
| `/apis/{apiId}/pages` | GET, POST | صفحات مستندات API |
| `/apis/{apiId}/media` | GET, POST | فایل‌های رسانه‌ای API |
| `/apis/{apiId}/groups` | GET | گروه‌های مرتبط با API |
| `/apis/{apiId}/quality-rules` | GET | ارزیابی کیفیت API |
| `/apis/{apiId}/ratings` | GET, POST | امتیازدهی API |

#### آنالیتیکس و مانیتورینگ API

| الگوی اندپوینت | متدها | توضیحات |
|----------------|-------|---------|
| `/apis/{apiId}/analytics` | GET | آنالیتیکس API (تعداد درخواست‌ها، تأخیر و...) |
| `/apis/{apiId}/logs` | GET | لاگ درخواست‌های API |
| `/apis/{apiId}/health` | GET | نتایج health check |
| `/apis/{apiId}/events` | GET | رویدادهای چرخه حیات API |
| `/apis/{apiId}/audits` | GET | گزارش ممیزی API |
| `/apis/{apiId}/alerts` | GET, POST | قواعد هشدار API |

#### مدیریت اپلیکیشن

| الگوی اندپوینت | متدها | توضیحات |
|----------------|-------|---------|
| `/applications` | GET, POST | لیست و ایجاد اپلیکیشن‌ها |
| `/applications/{appId}` | GET, PUT, DELETE | عملیات CRUD اپلیکیشن |
| `/applications/{appId}/keys` | GET, POST | مدیریت کلید API |
| `/applications/{appId}/members` | GET, POST | تیم اپلیکیشن |
| `/applications/{appId}/metadata` | GET, POST | متادیتای اپلیکیشن |
| `/applications/{appId}/logs` | GET | لاگ درخواست‌های اپلیکیشن |
| `/applications/{appId}/analytics` | GET | آنالیتیکس اپلیکیشن |
| `/applications/{appId}/alerts` | GET, POST | قواعد هشدار اپلیکیشن |

#### پلتفرم و پیکربندی

| الگوی اندپوینت | متدها | توضیحات |
|----------------|-------|---------|
| `/configuration` | GET | تنظیمات محیط |
| `/categories` | GET, POST | دسته‌بندی‌های API |
| `/groups` | GET, POST | گروه‌های کاربری |
| `/tags` | GET, POST | تگ‌های sharding |
| `/metadata` | GET, POST | متادیتای محیط |
| `/flows` | GET, PUT | flowهای سطح پلتفرم |
| `/policies` | GET | پالیسی‌های موجود |
| `/resources` | GET | منابع موجود |
| `/connectors` | GET | کانکتورهای موجود |
| `/fetchers` | GET | fetcherهای موجود |
| `/entrypoints` | GET | تعاریف entrypoint |
| `/analytics` | GET | آنالیتیکس سطح محیط |
| `/dashboards` | GET, POST | داشبوردهای سفارشی |
| `/notifiers` | GET | ارائه‌دهندگان اعلان |

#### مدیریت پورتال

| الگوی اندپوینت | متدها | توضیحات |
|----------------|-------|---------|
| `/portal/pages` | GET, POST | صفحات مستندات پورتال |
| `/portal/settings` | GET, PUT | تنظیمات پورتال |
| `/portal/media` | GET, POST | رسانه‌های پورتال |

### 4.3 Management API v2

**پایه**: `/v2` (ساختار RESTful تخت)

| دسته | الگوی اندپوینت | توضیحات |
|------|----------------|---------|
| **APIها** | `/apis` | CRUD، ایمپورت، اکسپورت، استقرار، شروع، توقف، تکثیر، مهاجرت |
| **پلن‌های API** | `/apis/{apiId}/plans` | مدیریت پلن |
| **اشتراک‌های API** | `/apis/{apiId}/subscriptions` | مدیریت اشتراک با اکسپورت و تأیید |
| **اعضای API** | `/apis/{apiId}/members` | مدیریت تیم، مالک اصلی |
| **آنالیتیکس API** | `/apis/{apiId}/analytics` | تعداد درخواست‌ها، زمان پاسخ، بازه‌های وضعیت |
| **سلامت API** | `/apis/{apiId}/health` | میانگین زمان پاسخ، دسترس‌پذیری، لاگ‌ها |
| **لاگ‌های API** | `/apis/{apiId}/logs` | لاگ درخواست‌ها با جزئیات |
| **ممیزی API** | `/apis/{apiId}/audits` | گزارش ممیزی |
| **رویدادهای API** | `/apis/{apiId}/events` | رویدادهای چرخه حیات |
| **امتیازدهی API** | `/apis/{apiId}/scoring` | امتیازدهی کیفیت API |
| **اپلیکیشن‌ها** | `/applications` | عملیات CRUD اپلیکیشن |
| **دسته‌بندی‌ها** | `/categories` | مدیریت دسته‌بندی با مرتبط‌سازی API |
| **گروه‌ها** | `/groups` | مدیریت گروه‌های کاربری |
| **ادغام‌ها** | `/integrations` | ادغام‌های شخص ثالث |
| **گروه‌های پالیسی مشترک** | `/environments/{envId}/shared-policy-groups` | گروه‌های پالیسی قابل استفاده مجدد |
| **کارهای ناهمزمان** | `/environments/{envId}/async-jobs` | ردیابی کارهای پس‌زمینه |
| **پلاگین‌ها** | `/plugins/entrypoints`، `/plugins/endpoints`، `/plugins/policies`، `/plugins/resources`، `/plugins/api-services` | کشف پلاگین |
| **UI** | `/ui`، `/ui/themes`، `/ui/portal-menu-links` | پیکربندی UI |
| **لایسنس** | `/license` | اطلاعات لایسنس |

### 4.4 Portal API

**پایه**: `/portal/environments/{envId}`

این اندپوینت‌ها UI پورتال توسعه‌دهنده را سرویس‌دهی می‌کنند و برای کاربران نهایی هستند.

| دسته | الگوی اندپوینت | توضیحات |
|------|----------------|---------|
| **بوت‌استرپ** | `/ui/bootstrap` | داده‌های راه‌اندازی اولیه پورتال |
| **APIها** | `/apis` | مرور و جستجوی APIهای منتشرشده |
| **جزئیات API** | `/apis/{apiId}` | اطلاعات API، تصویر، پس‌زمینه، متریکس، صفحات، پلن‌ها، امتیازات، رسانه |
| **امتیازدهی API** | `/apis/{apiId}/ratings` | ارسال و خواندن نظرات API |
| **دسته‌بندی‌ها** | `/categories` | مرور دسته‌بندی‌های API |
| **اپلیکیشن‌ها** | `/applications` | مدیریت اپلیکیشن‌های کاربر |
| **جزئیات اپلیکیشن** | `/applications/{appId}` | پیکربندی، اعضا، متادیتا، کلیدها، لاگ‌ها، آنالیتیکس |
| **اشتراک‌ها** | `/subscriptions` | اشتراک‌های کاربر با مدیریت کلید |
| **احراز هویت** | `/auth` | ورود، خروج، تبادل OAuth2 |
| **کاربر** | `/user` | پروفایل کاربر جاری و اعلان‌ها |
| **ثبت‌نام** | `/users` | ثبت‌نام کاربر جدید |
| **پیکربندی** | `/configuration` | پیکربندی پورتال |
| **صفحات** | `/pages` | صفحات مستندات پورتال |
| **تیکت‌ها** | `/tickets` | ارسال تیکت پشتیبانی |
| **تم** | `/theme` | داده‌های تم پورتال |
| **گروه‌ها** | `/groups` | گروه‌های کاربری موجود |
| **مجوزها** | `/permissions` | مجوزهای کاربر جاری |

### 4.5 مسیر فایل‌های سورس

| API | مسیر سورس |
|-----|-----------|
| Management v1 | `gravitee-apim-rest-api/gravitee-apim-rest-api-management/gravitee-apim-rest-api-management-rest/src/main/java/io/gravitee/rest/api/management/rest/resource/` |
| Management v2 | `gravitee-apim-rest-api/gravitee-apim-rest-api-management-v2/gravitee-apim-rest-api-management-v2-rest/src/main/java/io/gravitee/rest/api/management/v2/rest/resource/` |
| Portal | `gravitee-apim-rest-api/gravitee-apim-rest-api-portal/gravitee-apim-rest-api-portal-rest/src/main/java/io/gravitee/rest/api/portal/rest/resource/` |

---

*این مستند از سورس‌کد Gravitee APIM (نسخه 4.11.x) تولید شده است. برای آخرین اطلاعات، به سورس‌کد و مستندات رسمی Gravitee مراجعه کنید.*
