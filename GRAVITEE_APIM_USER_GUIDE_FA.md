## مقدمه

این راهنما دستورالعمل‌های جامع و گام‌به‌گام برای استفاده از **Gravitee API Management (APIM)** در یک محیط **Self-Hosted** ارائه می‌دهد. تمرکز راهنما بر جریان‌های کاری عملی و سناریوهای رایج برای **توسعه‌دهندگان و ناشران API** است.

### Gravitee APIM چیست؟

Gravitee APIM یک پلتفرم سبک و با کارایی بالا برای مدیریت API است که به شما امکان می‌دهد:
- APIها را ایجاد، ایمن‌سازی و منتشر کنید (REST، GraphQL، WebSocket، رویدادمحور)
- مصرف API را کنترل و اندازه‌گیری کنید
- سیاست‌ها (Policies) را برای امنیت، تبدیل/تغییر شکل داده و مدیریت ترافیک اعمال کنید
- عملکرد و میزان استفاده از API را پایش کنید
- یک Developer Portal متمرکز برای مصرف‌کنندگان API فراهم کنید

### درباره این راهنما

این مستندات پوشش می‌دهد:
- **مخاطب**: توسعه‌دهندگان و ناشران API
- **استقرار**: فقط محیط‌های Self-Hosted (ویژگی‌های مخصوص Cloud حذف شده‌اند)
- **تمرکز**: نحوه استفاده از محصول (نه نصب/راه‌اندازی)
- **پوشش**: همه انواع API (REST، رویدادمحور، WebSocket، GraphQL و …)

---

## مفاهیم پایه

قبل از ورود به جریان‌های کاری، مفاهیم کلیدی زیر را بشناسید:

### APIها در Gravitee

**APIهای v2**: APIهای پراکسی HTTP سنتی که درخواست‌ها را از مصرف‌کنندگان به سرویس‌های Backend هدایت می‌کنند. مناسب برای پراکسی ساده REST.

**APIهای v4**: APIهای پیشرفته با پشتیبانی از **میانجی‌گری پروتکل** (Protocol Mediation) که امکان جداسازی پروتکل مصرف‌کننده (HTTP، WebSocket، SSE، Webhook) از پروتکل Backend (REST، Kafka، MQTT، Solace و …) را فراهم می‌کنند.

### Entrypoint در برابر Endpoint

**Entrypoint**: نحوه دسترسی مصرف‌کننده به API (HTTP GET، HTTP POST، WebSocket، Server-Sent Events، Webhook)

**Endpoint**: سرویس‌ها/منابع Backend شما (REST API، Kafka Topic، MQTT Broker، Solace، RabbitMQ و …)

### Planها (پلن‌ها)

Planها مشخص می‌کنند مصرف‌کنندگان چگونه به API دسترسی داشته باشند و چه روش امنیت/احراز هویت لازم است:
- **Keyless**: بدون احراز هویت (دسترسی عمومی)
- **API Key**: احراز هویت ساده مبتنی بر توکن
- **OAuth2**: چارچوب استاندارد مجوزدهی
- **JWT**: اعتبارسنجی توکن JWT
- **mTLS**: احراز هویت مبتنی بر گواهی Mutual TLS

### Policyها (سیاست‌ها)

Policyها قوانین پردازشی هستند که روی درخواست‌ها و پاسخ‌های API اعمال می‌شوند و موارد زیر را پوشش می‌دهند:
- امنیت (احراز هویت، مجوزدهی، اعتبارسنجی)
- تبدیل/Transformation (تبدیل JSON/XML، نگاشت داده)
- مدیریت ترافیک (Rate Limiting، Circuit Breaker، Cache)
- لاگ‌گیری و مانیتورینگ

### Applicationها (اپلیکیشن‌ها)

Application نماینده نرم‌افزارهای کلاینتی هستند که APIهای شما را مصرف می‌کنند. توسعه‌دهندگان در Portal اپلیکیشن می‌سازند و آن را به پلن‌های API سابسکرایب می‌کنند تا اعتبارنامه دریافت کنند.

### Subscriptionها (اشتراک‌ها)

Subscription پیوند بین Application و Plan است. وقتی توسعه‌دهنده اپلیکیشن را به یک پلن از API سابسکرایب می‌کند، اعتبارنامه (مثل API Key) دریافت می‌کند.

---

## جریان کاری ۱: ساخت اولین REST API (v2)

این جریان کاری شما را برای ساخت یک پراکسی REST ساده با APIهای v2 هدایت می‌کند.

### چه زمانی از APIهای v2 استفاده کنیم؟

از v2 وقتی استفاده کنید که نیاز دارید:
- پراکسی ساده HTTP-to-HTTP
- مدیریت سنتی REST API
- اعمال Policy در سطح Request/Response
- پراکسی Backend ساده بدون میانجی‌گری پروتکل

### گام‌به‌گام: ساخت API v2

#### ۱) ورود به ویزارد ساخت API

1. وارد **Gravitee APIM Management Console** شوید
2. از منوی اصلی به **APIs** بروید
3. روی **+ Add API** یا **Create API** کلیک کنید
4. از گزینه‌ها، **v2 API** را انتخاب کنید

#### ۲) تنظیمات عمومی

اطلاعات پایه API را وارد کنید:
- **Name**: نام نمایشی API (مثلاً «Products API»)
- **Version**: شناسه نسخه (مثلاً «1.0»)
- **Description**: توضیح واضح از کارکرد API
- **Context Path**: مسیر URL قابل دسترس روی Gateway (مثلاً `/products`)

**نمونه**:
```
Name: Products API
Version: 1.0
Description: Provides access to product catalog information
Context Path: /products
```

#### ۳) تنظیمات پراکسی

Endpoint Backend را مشخص کنید:
- **Backend URL**: URL سرویس Backend (مثلاً `https://api.example.com/products`)
- **HTTP Methods**: روش‌های HTTP قابل ارائه (GET، POST، PUT، DELETE و …)

**نمونه**:
```
Backend URL: https://api.example.com/products
Methods: GET, POST, PUT, DELETE
```

#### ۴) تنظیم Load Balancing (اختیاری)

اگر چند نمونه Backend دارید:
1. روی **Add Endpoint** کلیک کنید تا Backendهای اضافی را اضافه کنید
2. یک **Load Balancing Algorithm** انتخاب کنید:
   - Round Robin
   - Random
   - Weighted Round Robin

**نمونه**:
```
Endpoint 1: https://api1.example.com/products (Weight: 70%)
Endpoint 2: https://api2.example.com/products (Weight: 30%)
Algorithm: Weighted Round Robin
```

#### ۵) تنظیم Health Check (اختیاری)

برای مانیتور کردن سلامت Backend:
1. **Health Check** را فعال کنید
2. موارد زیر را تنظیم کنید:
   - **Interval**: هر چند وقت یک‌بار (مثلاً 30 ثانیه)
   - **Endpoint**: مسیر Health (مثلاً `/health`)
   - **Success Threshold**: چند موفقیت پیاپی برای سالم بودن لازم است

**نمونه**:
```
Enabled: Yes
Interval: 30s
Path: /health
Method: GET
Success Threshold: 2
```

#### ۶) دسترسی کاربران و گروه‌ها

کنترل کنید چه کسانی می‌توانند API را مدیریت کنند:
1. به **User and Group Access** بروید
2. کاربران/گروه‌ها را با نقش مناسب اضافه کنید:
   - **Primary Owner**: کنترل کامل
   - **Owner**: مدیریت تنظیمات
   - **User**: فقط مشاهده

#### ۷) ذخیره و Deploy

1. روی **Save** کلیک کنید تا API ساخته شود
2. روی **Deploy** کلیک کنید تا روی Gateway فعال شود
3. وضعیت Deploy را بررسی کنید

**API شما ساخته شد اما هنوز برای مصرف‌کنندگان قابل استفاده نیست. حالا باید پلن‌های امنیتی اضافه کنید.**

---

## جریان کاری ۲: ساخت APIهای پیشرفته (v4)

APIهای v4 قابلیت‌های پیشرفته‌ای مثل میانجی‌گری پروتکل و معماری رویدادمحور را ارائه می‌دهند.

### چه زمانی از v4 استفاده کنیم؟

از v4 وقتی استفاده کنید که نیاز دارید:
- میانجی‌گری پروتکل (مثلاً مصرف‌کننده HTTP با Backend Kafka)
- الگوهای رویدادمحور
- پشتیبانی WebSocket، SSE یا Webhook
- اعمال Policy در سطح پیام
- قابلیت‌های Asynchronous

### گام‌به‌گام: ساخت API v4

#### ۱) ورود به ویزارد ساخت v4

1. وارد **APIM Management Console** شوید
2. به **APIs** بروید
3. روی **+ Add API** کلیک کنید
4. **v4 API** را انتخاب کنید

#### ۲) تنظیمات عمومی

مشابه v2:
- **Name**
- **Version**
- **Description**
- **Context Path**

#### ۳) تعریف Entrypointها

انتخاب کنید مصرف‌کننده چگونه به API دسترسی داشته باشد:

**HTTP GET**
- مناسب برای: عملیات read-only
- کاربرد: polling، دریافت منابع

**HTTP POST**
- مناسب برای: عملیات کامل HTTP (دوطرفه)
- کاربرد: CRUD، درخواست‌های synchronous

**Server-Sent Events (SSE)**
- مناسب برای: استریم یک‌طرفه از سرور به کلاینت
- کاربرد: اعلان‌ها و به‌روزرسانی لحظه‌ای

**WebSocket**
- مناسب برای: اتصال پایدار دوطرفه
- کاربرد: ارتباط لحظه‌ای، چت

**Webhook**
- مناسب برای: callbackهای HTTP رویدادمحور
- کاربرد: اعلان رویداد به‌صورت asynchronous

**نمونه پیکربندی**:
```
Selected Entrypoints:
- HTTP POST (for synchronous access)
- WebSocket (for real-time updates)

HTTP POST Configuration:
  Context Path: /api/events

WebSocket Configuration:
  Context Path: /ws/events
```

#### ۴) انتخاب Endpointها (Backend)

نوع Backend را انتخاب کنید:

**REST API**
- Backend استاندارد HTTP
- پیکربندی: Backend URL و روش‌ها

**Kafka**
- اتصال به Topicهای Kafka
- پیکربندی: Bootstrap servers، topics، تنظیمات consumer/producer

**MQTT5**
- مناسب IoT
- پیکربندی: broker، topicها، QoS

**Solace**
- Event broker سازمانی
- پیکربندی: URL، queue/topic

**RabbitMQ**
- Message queue
- پیکربندی: host، exchange، routing key

**Mock**
- برای توسعه/تست

**Azure Service Bus**
- پیام‌رسانی مبتنی بر Cloud

**نمونه پیکربندی**:
```
Selected Endpoint: Kafka

Configuration:
  Bootstrap Servers: kafka1.example.com:9092,kafka2.example.com:9092
  Topics: user-events, order-events
  Consumer Group: apim-consumers
  Auto Offset Reset: earliest
```

#### ۵) تنظیم Quality of Service (QoS)

برای APIهای رویدادمحور، تضمین تحویل پیام را مشخص کنید:
- **None**: بدون تضمین
- **Auto**: ACK هنگام دریافت
- **At-Most-Once**: حداکثر یک‌بار (ممکن است از دست برود)
- **At-Least-Once**: حداقل یک‌بار (ممکن است تکرار شود)

#### ۶) اعمال Policyهای اولیه

1. روی **Policy Studio** کلیک کنید
2. Policyهای پایه را اضافه کنید (جزئیات در جریان کاری ۴)
3. روی **Save** کلیک کنید

#### ۷) ذخیره و Deploy

1. **Save**
2. **Deploy**

**API v4 شما ساخته شد. حالا برای کنترل دسترسی پلن‌های امنیتی اضافه کنید.**

---

## جریان کاری ۳: امن‌سازی APIها با Plan

Planها تعیین می‌کنند توسعه‌دهندگان چگونه به API دسترسی داشته باشند و چه احراز هویتی لازم است.

### درک انواع Plan

#### Plan بدون کلید (Keyless)
**کاربرد**: API عمومی بدون احراز هویت  
**امنیت**: ندارد  
**زمان استفاده**:
- APIهای داده عمومی
- محیط‌های تست/توسعه
- API بدون داده حساس

**گام‌های پیکربندی**:
1. وارد API شوید
2. **Plans** → **Add Plan**
3. **Keyless**
4. تنظیمات:
   - **Name**: مثل "Public Access"
   - **Description**
   - **Rate Limiting** (اختیاری)
5. **Save** و **Publish**

**نمونه**:
```
Plan Name: Public Access
Type: Keyless
Rate Limit: 1000 requests per minute
Auto-validation: Yes (subscriptions auto-approved)
```

---

#### Plan کلید API (API Key)
**کاربرد**: احراز هویت ساده همراه با ردیابی مصرف‌کننده  
**امنیت**: متوسط  
**زمان استفاده**:
- APIهای داخلی
- یکپارچه‌سازی با شریک‌ها
- نیاز به گزارش‌گیری مصرف

**گام‌های پیکربندی**:
1. API → **Plans** → **Add Plan**
2. **API Key**
3. تنظیمات:
   - **Name**: مثل "Standard Access"
   - **Description**
   - **Auto-validation**
   - **Rate Limiting**
4. **Save** و **Publish**

**نحوه کار**:
- توسعه‌دهنده subscribe می‌کند و API key می‌گیرد
- در درخواست ارسال می‌کند:
  - Header: `X-Gravitee-Api-Key: {api-key}`
  - Query: `?api-key={api-key}`

**نمونه پیکربندی**:
```
Plan Name: Standard Access
Type: API Key
Auto-validation: No (requires manual approval)
Rate Limit: 5000 requests per day
Quota: 100,000 requests per month
```

**نمونه فراخوانی API**:
```bash
curl -X GET "https://gateway.example.com/products" \
  -H "X-Gravitee-Api-Key: a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
```

---

#### Plan OAuth2
**کاربرد**: مجوزدهی تفویض‌شده و دسترسی ثالث  
**امنیت**: بالا  
**زمان استفاده**:
- APIهای عمومی
- یکپارچه‌سازی ثالث
- اپ‌هایی با نیاز به رضایت کاربر

**گام‌های پیکربندی**:
1. API → **Plans** → **Add Plan**
2. **OAuth2**
3. تنظیمات:
   - **Name**
   - **Authorization Server**
   - **Token Endpoint**
   - **Introspection Endpoint**
   - **Scopes**
4. **Save** و **Publish**

**نمونه پیکربندی**:
```
Plan Name: OAuth2 Access
Type: OAuth2
Authorization Server: https://auth.example.com
Token Endpoint: https://auth.example.com/oauth/token
Introspection Endpoint: https://auth.example.com/oauth/introspect
Required Scopes: read:products, write:products
Client Authentication: Required
```

**نحوه کار**:
1. توسعه‌دهنده اپ را ثبت می‌کند و client credentials می‌گیرد
2. token می‌گیرد
3. token را در درخواست می‌فرستد:
```bash
curl -X GET "https://gateway.example.com/products" \
  -H "Authorization: Bearer {access-token}"
```

---

#### Plan JWT
**کاربرد**: احراز هویت مبتنی بر JWT در زیرساخت موجود  
**امنیت**: بالا  
**زمان استفاده**:
- معماری microservices
- APIهای داخلی با JWT موجود
- احراز هویت Stateless

**گام‌های پیکربندی**:
1. API → **Plans** → **Add Plan**
2. **JWT**
3. تنظیمات:
   - **Signature Verification**: Public Key یا JWKS یا Shared Secret
   - **Issuer**
   - **Claims Validation**
4. **Save** و **Publish**

**نمونه پیکربندی**:
```
Plan Name: JWT Access
Type: JWT
Signature Algorithm: RS256
Public Key: [RSA Public Key]
Issuer: https://auth.example.com
Required Claims:
  - aud: api.example.com
  - scope: api.access
Token Location: Authorization header
```

**نمونه فراخوانی**:
```bash
curl -X GET "https://gateway.example.com/products" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

#### Plan mTLS
**کاربرد**: احراز هویت متقابل مبتنی بر گواهی  
**امنیت**: بسیار بالا  
**زمان استفاده**:
- یکپارچه‌سازی B2B
- APIهای بسیار حساس
- نیاز به امنیت گواهی‌محور

**گام‌های پیکربندی**:
1. API → **Plans** → **Add Plan**
2. **mTLS**
3. تنظیمات:
   - **Client Certificate Requirement**
   - **Certificate Chain Validation**
   - **Trusted CAs**
4. **Save** و **Publish**

**نمونه**:
```
Plan Name: Certificate Access
Type: mTLS
Client Certificate: Required
Certificate Chain Validation: Enabled
Trusted CAs: [Upload CA certificate]
Certificate Subject DN Validation: CN=*.example.com
```

**نحوه کار**:
- کلاینت در handshake گواهی ارائه می‌دهد
- Gateway آن را در برابر CAهای مورد اعتماد بررسی می‌کند
- فقط دارنده گواهی معتبر دسترسی می‌گیرد

---

### انتشار Planها

بعد از ساخت Plan:
1. تنظیمات را بازبینی کنید
2. روی **Publish** کلیک کنید
3. تا وقتی Plan منتشر نشده، توسعه‌دهندگان نمی‌توانند subscribe کنند

---

## جریان کاری ۴: اعمال Policyها

Policyها برای امنیت، تبدیل داده، مدیریت ترافیک و … به API قابلیت اضافه می‌کنند.

### درک Policy Studio

Policy Studio محیط ساخت جریان پر��ازش Request/Response با اضافه‌کردن Policyهاست.

**مفاهیم کلیدی**:
- **Flow**: زنجیره اجرای Policyها
- **Phase**: مرحله Request (قبل از Backend) و Response (بعد از Backend)
- **Condition**: اجرای شرطی بر اساس مسیر، هدر و …

### دسترسی به Policy Studio

1. وارد API شوید
2. از منو **Policy Studio**
3. نوع Flow را انتخاب کنید:
   - **Request Flow**
   - **Response Flow**
   - **Publish Flow** (v4)
   - **Subscribe Flow** (v4)

---

### سناریوهای رایج Policy

#### سناریو ۱: Rate Limiting

**گام‌ها**:
1. **Policy Studio**
2. در **Request Flow** → **+ Add Policy**
3. **Rate Limit**
4. تنظیم:
   - نوع Rate Limit: Per Consumer یا Per API
   - Limit
   - Time Unit
   - Key
5. **Save**
6. **Deploy API**

**نمونه**:
```
Policy: Rate Limit
Type: Per Consumer
Limit: 1000 requests per minute
Async: No
Add Headers: Yes (X-RateLimit-Limit, X-RateLimit-Remaining)
```

**نتیجه**: اگر بیشتر از حد باشد `429 Too Many Requests` برمی‌گردد.

---

#### سناریو ۲: تبدیل پاسخ‌های JSON

**گام‌ها**:
1. **Policy Studio**
2. در **Response Flow** → **+ Add Policy**
3. Policy تبدیل **JSON to JSON**
4. تعریف Transformation (JOLT یا نگاشت ساده)
5. **Save**
6. **Deploy API**

**نمونه**:
```
Policy: JSON to JSON
Scope: RESPONSE_CONTENT
Transformation Spec (JOLT):
[
  {
    "operation": "shift",
    "spec": {
      "data": {
        "*": {
          "id": "items[&1].productId",
          "name": "items[&1].productName",
          "price": "items[&1].cost"
        }
      }
    }
  }
]
```

**قبل**:
```json
{
  "data": [
    {"id": 1, "name": "Widget", "price": 9.99},
    {"id": 2, "name": "Gadget", "price": 19.99}
  ]
}
```

**بعد**:
```json
{
  "items": [
    {"productId": 1, "productName": "Widget", "cost": 9.99},
    {"productId": 2, "productName": "Gadget", "cost": 19.99}
  ]
}
```

---

#### سناریو ۳: لاگ‌گیری درخواست

**گام‌ها**:
1. **Policy Studio**
2. در **Request Flow** → **+ Add Policy**
3. **Logging**
4. تنظیم:
   - Scope
   - Mode
   - Content
5. **Save**
6. **Deploy API**

**نمونه**:
```
Policy: Logging
Scope: REQUEST and RESPONSE
Mode: CLIENT_PROXY
Content: Include headers and payload
```

**نکته**: در تولید، لاگ‌گیری انتخابی برای جلوگیری از افت عملکرد انجام دهید.

---

#### سناریو ۴: فعال‌سازی CORS

**گام‌ها**:
1. API → **Proxy** → **CORS**
2. CORS را فعال کنید
3. تنظیم:
   - Allowed Origins
   - Allowed Methods
   - Allowed Headers
   - Exposed Headers
   - Max Age
4. **Save**
5. **Deploy API**

**نمونه**:
```
CORS Enabled: Yes
Allowed Origins: https://app.example.com, https://admin.example.com
Allowed Methods: GET, POST, PUT, DELETE, OPTIONS
Allowed Headers: Content-Type, Authorization, X-Custom-Header
Exposed Headers: X-RateLimit-Limit, X-RateLimit-Remaining
Allow Credentials: Yes
Max Age: 3600
```

---

#### سناریو ۵: اعتبارسنجی Payload درخواست

**گام‌ها**:
1. **Policy Studio**
2. در **Request Flow** → **+ Add Policy**
3. **JSON Validation**
4. تنظیم:
   - JSON Schema
   - پیام خطا
   - Status code (مثلاً 400)
5. **Save**
6. **Deploy API**

**نمونه**:
```json
{
  "type": "object",
  "properties": {
    "name": {"type": "string", "minLength": 1},
    "email": {"type": "string", "format": "email"},
    "age": {"type": "integer", "minimum": 0}
  },
  "required": ["name", "email"]
}
```

---

#### سناریو ۶: Circuit Breaker

**گام‌ها**:
1. **Policy Studio**
2. در **Request Flow** → **+ Add Policy**
3. **Circuit Breaker**
4. تنظیم:
   - Failure Threshold
   - Timeout
   - Success Threshold
5. **Save**
6. **Deploy API**

**نمونه**:
```
Policy: Circuit Breaker
Failure Threshold: 5 failures
Timeout: 30 seconds
Success Threshold: 3 successful requests
```

**نحوه کار**:
1. **Closed**: حالت عادی
2. **Open**: پس از ۵ خطا، درخواست‌ها سریع Fail می‌شوند
3. **Half-Open**: بعد از ۳۰ ثانیه، چند درخواست تست
4. **Closed**: در صورت موفقیت تست‌ها

---

### مرجع دسته‌بندی Policyها

#### Policyهای امنیتی
- API Key
- OAuth2
- JWT
- Basic Authentication
- mTLS
- SSL Enforcement
- IP Filtering
- LDAP Authentication

#### Policyهای تبدیل/Transformation
- JSON to JSON
- JSON to XML
- XML to JSON
- XML to SOAP
- REST to SOAP
- Avro to JSON
- Protobuf to JSON
- Transform Headers
- Transform Query Parameters
- URL Rewriting
- Groovy Script

#### Policyهای مدیریت ترافیک
- Rate Limit
- Quota
- Spike Arrest
- Circuit Breaker
- Retry
- Timeout
- Cache
- Traffic Shadowing

#### Policyهای مسیریابی
- Dynamic Routing
- Request Validation
- Mock Response

#### Policyهای پایش
- Logging
- Metrics Reporter
- Custom Metrics

---

## جریان کاری ۵: انتشار APIها در Developer Portal

APIهای خود را قابل کشف و قابل استفاده برای توسعه‌دهندگان کنید.

### گام‌به‌گام: انتشار API

#### ۱) تکمیل پیکربندی API

اطمینان حاصل کنید:
- حداقل یک Plan منتشر شده دارید
- مستندات کامل است
- نام و توضیحات مناسب است

#### ۲) افزودن مستندات API

1. API → **Documentation**
2. **+ Add Documentation**
3. نوع مستند:
   - OpenAPI/Swagger
   - AsyncAPI
   - Markdown
   - AsciiDoc
4. بارگذاری/چسباندن محتوا
5. **Save**

**نمونه OpenAPI**:
```yaml
openapi: 3.0.0
info:
  title: Products API
  version: 1.0.0
  description: Access product catalog
paths:
  /products:
    get:
      summary: List all products
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Product'
components:
  schemas:
    Product:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
        price:
          type: number
```

#### ۳) تنظیم متادیتای API

1. **Info** یا **General Settings**
2. افزودن:
   - Categories
   - Labels
   - Picture
3. **Save**

#### ۴) انتشار در Portal

1. به **Deployment** یا **Portal** بروید
2. گزینه **Published to Portal** را روشن کنید
3. **Save**

**API شما اکنون در Developer Portal قابل مشاهده است.**

---

### مدیریت Visibility

**Public**:
- قابل مشاهده برای همه کاربران Portal

**Private**:
- فقط برای گروه‌های مشخص

**پیکربندی**:
1. **User and Group Access**
2. در **Portal Visibility**:
   - Public
   - Private
3. اگر Private، گروه‌های مجاز را اضافه کنید
4. **Save**

---

## جریان کاری ۶: مدیریت Application و Subscription

### برای ناشران: مدیریت درخواست‌های Subscription

#### مشاهده درخواست‌ها

1. API → **Subscriptions** → **Subscription Requests**
2. موارد در انتظار را بررسی کنید:
   - نام Application
   - Plan
   - مالک/توسعه‌دهنده
   - تاریخ

#### تأیید یا رد Subscription

1. روی درخواست کلیک کنید
2. جزئیات Application را بررسی کنید
3. یکی را انتخاب کنید:
   - **Accept**
   - **Reject**
4. پیام (اختیاری)
5. **Confirm**

**در Subscriptionهای تأیید شده**:
- اعتبارنامه تولید می‌شود (برای API Key، کلید ایجاد می‌شود)
- فعال می‌شود
- اعلان ارسال می‌شود

#### مدیریت Subscriptionهای فعال

1. **Subscriptions** → **Manage Subscriptions**
2. اقدامات:
   - Pause / Resume
   - Close
   - Renew Keys
   - Transfer

**بستن Subscription**:
1. Subscription را انتخاب کنید
2. **Close**
3. تأیید
4. دسترسی بلافاصله قطع می‌شود

---

### برای مصرف‌کنندگان: ساخت Application و Subscribe

این بخش در جریان کاری Portal (شماره ۹) آمده است.

---

## جریان کاری ۷: مانیتورینگ و آنالیتیکس

Gravitee APIM ابزارهای کامل برای پایش عملکرد و مصرف API دارد.

### داشبوردها

#### داشبورد سطح API

1. API → **Analytics** یا **Dashboard**
2. مشاهده:
   - تعداد درخواست‌ها
   - زمان پاسخ (میانگین/حداقل/حداکثر/صدک‌ها)
   - نرخ خطا
   - Top Consumers
   - توزیع Status Code
   - توزیع جغرافیایی (در صورت فعال بودن)

**انتخاب بازه زمانی**:
- یک ساعت اخیر
- ۲۴ ساعت اخیر
- ۷ روز اخیر
- ۳۰ روز اخیر
- بازه سفارشی

#### داشبورد سراسری پلتفرم

1. از منوی اصلی **Dashboard** یا **Analytics**
2. مشاهده:
   - مجموع فراخوانی‌ها
   - روند زمان پاسخ
   - نرخ خطا
   - Top APIها
   - وضعیت سلامت پلتفرم

---

### مشاهده Request Logها

#### فعال‌سازی Logging

1. API → **Analytics** → **Logging**
2. تنظیم:
   - Mode: None / Client Only / Proxy Only / Client and Proxy
   - Content: شامل payload یا فقط headers
   - Sampling: درصد لاگ (مثلاً 10%)
3. **Save** و **Deploy API**

**هشدار**: Logging با content فعال روی عملکرد و ذخیره‌سازی اثر می‌گذارد.

#### مشاهده Logها

1. **Analytics** → **Logs**
2. فیلتر با:
   - زمان
   - status code
   - application
   - plan
3. جزئیات هر رکورد:
   - request/response
   - زمان‌ها
   - policyهای اجرا شده
   - خطاها

**نمونه**:
```
Timestamp: 2024-01-15 14:32:45
API: Products API
Application: Mobile App
Plan: Standard Access
Method: GET /products?category=electronics
Status: 200 OK
Response Time: 245ms

Request Headers:
  X-Gravitee-Api-Key: a1b2c3d4...
  Accept: application/json

Response Headers:
  Content-Type: application/json
  X-RateLimit-Remaining: 950

Policies Executed:
  1. Rate Limit (5ms)
  2. API Key (12ms)
  3. Transform Headers (3ms)
```

---

### امتیاز کیفیت API

#### مشاهده Quality Score

1. **Analytics** → **API Quality** (یا زیر تنظیمات پلتفرم)
2. معیارها:
   - کامل بودن مستندات
   - لوگو/تصویر
   - دسته‌بندی
   - برچسب‌ها
   - Health Check
   - کیفیت توضیحات

**Quality Score**: از ۰ تا ۱۰۰٪

#### بهبود Quality Score

1. مستندات کامل اضافه کنید
2. Health check تنظیم کنید
3. لوگو اضافه کنید
4. دسته‌ها و labels تعیین کنید
5. توضیحات بهتر بنویسید
6. API را در Portal منتشر کنید

---

### Audit Trail (ردیابی تغییرات)

#### دسترسی

1. **Audit** یا **Settings** → **Audit Trail**
2. مشاهده تغییرات:
   - ایجاد/به‌روزرسانی/Deploy API
   - publish/close plan
   - تأیید/رد subscription
   - تغییر دسترسی کاربران
   - تغییرات تنظیمات

#### فیلترها

- بر اساس API
- نوع رویداد
- کاربر
- بازه زمانی

**نمونه**:
```
Date: 2024-01-15 14:30:00
User: admin@example.com
Event: API_DEPLOYED
API: Products API (v1.0)
Details: Deployed API with Rate Limit policy updated
```

---

### تنظیم Reporterها

#### Reporterهای موجود

- Elasticsearch
- File Reporter
- TCP Reporter
- Datadog

#### نمونه: Elasticsearch

1. **Settings** → **Analytics** → **Reporters**
2. **+ Add Reporter**
3. **Elasticsearch**
4. تنظیم:
   - Hosts
   - Index Name
   - Index Mode
   - Authentication
5. **Save**

**نمونه**:
```
Reporter: Elasticsearch
Hosts: https://es1.example.com:9200, https://es2.example.com:9200
Index: gravitee-metrics
Index Mode: Daily (gravitee-metrics-2024-01-15)
Authentication: Basic (username/password)
SSL Verification: Enabled
```

---

### یکپارچه‌سازی OpenTelemetry

#### فعال‌سازی

1. **Settings** → **OpenTelemetry**
2. فعال کنید
3. تنظیم:
   - Endpoint
   - Protocol: gRPC یا HTTP
   - Service Name
4. **Save**

**نمونه**:
```
Enabled: Yes
Endpoint: https://otel-collector.example.com:4317
Protocol: gRPC
Service Name: gravitee-apim-gateway
```

#### مشاهده Traceها

- در backendهای OTEL مثل Jaeger/Zipkin
- شامل:
  - مسیر request
  - زمان اجرای policyها
  - زمان تماس با backend
  - latency کل

---

## جریان کاری ۸: سناریوهای پیشرفته

### APIهای رویدادمحور با Kafka

Kafka topicها را به REST/WebSocket/SSE ارائه کنید.

#### سناریوی نمونه

Topic: `user-events`  
ارائه به صورت:
- REST برای مصرف synchronous
- WebSocket برای استریم real-time

#### گام‌به‌گام: ساخت Kafka API

##### ۱) ساخت v4 API

1. **APIs** → **+ Add API**
2. **v4 API**
3. تنظیمات:
   - **Name**: User Events API
   - **Version**: 1.0
   - **Context Path**: `/user-events`

##### ۲) Entrypointها

**HTTP POST**:
```
Context Path: /user-events
Message Timeout: 5000ms (wait for message)
```

**WebSocket**:
```
Context Path: /ws/user-events
Publisher: Disabled (consumer only)
```

##### ۳) Endpoint Kafka

```
Bootstrap Servers: kafka1.example.com:9092,kafka2.example.com:9092
Topics: user-events
Consumer Group: apim-user-events-consumers
Auto Offset Reset: latest
Initial Offset: EARLIEST or LATEST
Security Protocol: PLAINTEXT (or SASL_SSL for secure)
```

**نمونه SASL**:
```
Security Protocol: SASL_SSL
SASL Mechanism: PLAIN (or SCRAM-SHA-256, SCRAM-SHA-512)
SASL Username: kafka-user
SASL Password: [password]
```

##### ۴) QoS

```
QoS: Auto (acknowledgment sent when message received)
```

##### ۵) Policyها

- API Key
- Rate Limit
- JSON Validation

##### ۶) Planها

Plan امنیتی مناسب (مثلاً API Key) بسازید.

##### ۷) Deploy

**Save** → **Deploy**

#### مصرف Kafka API

**REST (HTTP POST)**:
```bash
curl -X POST "https://gateway.example.com/user-events" \
  -H "X-Gravitee-Api-Key: your-api-key" \
  -H "Content-Type: application/json"
```

**نمونه پاسخ**:
```json
{
  "id": "msg-12345",
  "data": {
    "userId": 42,
    "action": "login",
    "timestamp": "2024-01-15T14:30:00Z"
  }
}
```

**WebSocket**:
```javascript
const ws = new WebSocket('wss://gateway.example.com/ws/user-events?api-key=your-api-key');

ws.onopen = () => {
  console.log('Connected to user events stream');
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Received event:', message);
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};
```

---

### APIهای WebSocket

#### سناریو نمونه

ساخت API چت با WebSocket

#### گام‌به‌گام: ساخت WebSocket API

##### ۱) ساخت v4 API

1. **APIs** → **+ Add API**
2. **v4 API**
3. تنظیمات:
   - **Name**: Chat API
   - **Version**: 1.0
   - **Context Path**: `/chat`

##### ۲) Entrypoint WebSocket

```
Context Path: /ws/chat
Publisher: Enabled (bidirectional)
Subscriber: Enabled (bidirectional)
```

##### ۳) Backend

- WebSocket proxy
- Kafka/MQTT
- Mock

**نمونه WebSocket Backend**:
```
Backend URL: wss://chat-backend.example.com/socket
```

##### ۴) Policyها

- JWT برای احراز هویت اتصال
- Rate Limit برای پیام‌ها

##### ۵) Deploy

**Save** → **Deploy**

#### اتصال به WebSocket API

```javascript
const ws = new WebSocket('wss://gateway.example.com/ws/chat', {
  headers: {
    'Authorization': 'Bearer your-jwt-token'
  }
});

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'message',
    content: 'Hello, world!'
  }));
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
};
```

---

### Shared Policy Group (گروه سیاست مشترک)

بازاستفاده از ترکیب Policyها بین چند API.

#### سناریو

۱۰ API دارید که همگی به سیاست امنیت و Rate Limit یکسان نیاز دارند.

#### گام‌به‌گام: ساخت Shared Policy Group

##### ۱) دسترسی

1. **Policies** → **Shared Policy Groups** (ممکن است زیر Settings باشد)
2. **+ Create Policy Group**

##### ۲) پیکربندی

- **Name**: Standard Security
- **Description**: API Key + Rate Limit + CORS
- **Phase**: Request

##### ۳) اضافه‌کردن Policyها

- API Key
- Rate Limit
- CORS

##### ۴) اعمال روی APIها

**در زمان ساخت API**: در Policy Studio → **+ Add Shared Policy Group**

**برای API موجود**: Policy Studio → Add Shared Policy Group → Save → Deploy

#### مزایا

- یکسان‌سازی
- نگهداری آسان
- سرعت در راه‌اندازی

---

### Import/Export API

برای مهاجرت بین محیط‌ها یا بکاپ گرفتن.

#### Export

1. API → **General/Settings**
2. **Export**
3. فرمت:
   - JSON
   - Gravitee Definition
4. دانلود فایل

**شامل**:
- تنظیمات API
- planها
- policyها
- مستندات
- resourceها

#### Import

1. **APIs** → **Import**
2. فایل را آپلود کنید
3. تنظیمات را بازبینی کنید (context path، backend URL و …)
4. **Import**
5. تنظیمات محیط مقصد را به‌روزرسانی کنید
6. Deploy

**نکته**: اطلاعات حساس (secretها، کلیدها) را بعد از import تنظیم کنید.

---

## جریان کاری ۹: Developer Portal (برای مصرف‌کنندگان)

### دسترسی به Portal

**آدرس Portal**: معمولاً `https://portal.example.com`

1. Portal را در مرورگر باز کنید
2. ثبت‌نام/ورود:
   - Self-Registration (در صورت فعال بودن)
   - SSO
   - Invitation

---

### کشف APIها

#### مرور کاتالوگ

1. از صفحه اصلی Portal کاتالوگ را ببینید
2. کارت‌ها شامل:
   - نام و نسخه
   - توضیحات
   - دسته‌ها/labelها
   - ناشر
3. فیلترها:
   - Category
   - Label
   - Search

#### مشاهده جزئیات API

1. روی کارت کلیک کنید
2. مشاهده:
   - Overview
   - Documentation
   - Plans
   - Versions

#### خواندن مستندات و Try It

1. تب **Documentation**
2. مشاهده تعاملی endpointها
3. در صورت فعال بودن **Try It**، درخواست را تست کنید

---

### ساخت Application

#### گام‌به‌گام

1. Portal → **Applications**
2. **+ Create Application**
3. وارد کنید:
   - Name
   - Description
   - Type: Browser / Native / Backend to Backend / Web
   - Client ID (برای OAuth2/JWT معمولاً خودکار)
4. **Create**

**نمونه**:
```
Name: E-commerce Mobile App
Description: iOS and Android app for product browsing and ordering
Type: Native
Owner: developer@example.com
```

---

### Subscribe به API

#### گام‌به‌گام

1. در Portal وارد صفحه API شوید
2. **Subscribe**
3. انتخاب:
   - Application
   - Plan
4. اطلاعات اضافی (در صورت نیاز)
5. **Request Subscription**

**پلن‌های Auto-Approved**: سریع فعال می‌شوند  
**Manual Approval**: نیاز به تأیید ناشر دارد

#### مشاهده Subscription

بعد از تأیید:
1. **Applications** → اپلیکیشن
2. تب **Subscriptions**
3. مشاهده:
   - API
   - Plan
   - Status
   - API Key
   - تاریخ
   - آمار مصرف

**نمونه**:
```
API: Products API v1.0
Plan: Standard Access
Status: Active
API Key: a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d
Created: 2024-01-15
Quota: 50,000 / 100,000 requests (50%)
```

---

### استفاده از اعتبارنامه‌ها

#### API Key

**Header (پیشنهادی)**:
```bash
curl -X GET "https://gateway.example.com/products" \
  -H "X-Gravitee-Api-Key: a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
```

**Query**:
```bash
curl -X GET "https://gateway.example.com/products?api-key=a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
```

#### OAuth2

```bash
curl -X POST "https://auth.example.com/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=your-client-id" \
  -d "client_secret=your-client-secret" \
  -d "scope=read:products"

curl -X GET "https://gateway.example.com/products" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

### مانیتورینگ مصرف Application

#### مشاهده Analytics

1. **Applications** → اپلیکیشن
2. **Analytics/Dashboard**
3. مشاهده:
   - تعداد درخواست‌ها
   - زمان پاسخ
   - نرخ خطا
   - میزان مصرف quota
   - تفکیک بر اساس API

#### مشاهده Logها

1. در Application به **Logs**
2. فیلتر بر اس��س API/زمان/status

---

### مدیریت Subscriptionها

#### Renew API Key

1. Application → Subscriptions
2. Subscription را انتخاب کنید
3. **Renew Key/Regenerate**
4. کلید جدید را در اپ به‌روزرسانی کنید
5. کلید قبلی فوراً بی‌اعتبار می‌شود

#### لغو Subscription

1. Subscription details
2. **Cancel/Unsubscribe**
3. تأیید
4. دسترسی قطع می‌شود

---

### تنظیمات Application

#### ویرایش

1. **Applications** → اپلیکیشن
2. **Settings/Edit**
3. به‌روزرسانی:
   - Name
   - Description
   - Type
   - Callback URLs (برای OAuth2)
4. **Save**

#### مدیریت اعضا

1. Application → **Members/Team**
2. **+ Add Member**
3. ایمیل و نقش:
   - Owner
   - User
4. **Add**

---

## بهترین‌روش‌ها

### طراحی API

**نام‌گذاری یکسان**
- context path: حروف کوچک، خط تیره (`/user-management`)
- نام API: واضح
- نسخه‌ها: semantic versioning

**نسخه‌گذاری**
- نسخه در مسیر (`/v1/products`) یا هدر
- سازگاری عقب‌رو تا حد امکان
- مستندسازی تغییرات شکستن‌زا

**مستندسازی کامل**
- OpenAPI/Swagger
- مثال برای همه endpointها
- خطاها و کدها
- به‌روزرسانی همگام با تغییرات

---

### امنیت

**انتخاب Plan مناسب**
- داده عمومی: Keyless (با rate limiting)
- داخلی: API Key
- ثالث: OAuth2
- حساس: mTLS یا JWT

**Rate Limiting**
- جلوگیری از سوءاستفاده
- تنظیم برای tierهای مختلف
- پایش و تنظیم

**اعتبارسنجی ورودی**
- JSON/XML validation
- sanitize ورودی‌ها

**رمزنگاری داده حساس**
- HTTPS
- عدم لاگ اطلاعات حساس
- چرخش دوره‌ای اعتبارنامه‌ها

---

### کارایی

**Caching**
- برای داده‌های پرتکرار و کم‌تغییر
- TTL مناسب
- برای GET

**Health Check**
- پایش Backend
- Circuit breaker
- Retry با backoff

**Logging بهینه**
- Sampling (۱۰–۲۰٪)
- عدم لاگ payloadهای بزرگ
- سطح لاگ مناسب

**پایش زمان پاسخ**
- بودجه عملکردی
- شناسایی endpointهای کند
- بهینه‌سازی Backend

---

### حاکمیت (Governance)

**Category و Label**
- سازمان‌دهی بر اساس دامنه
- برچسب چرخه عمر (beta/stable/deprecated)

**استاندارد کیفیت**
- کیفیت بال��
- مستندات کامل
- نام‌گذاری یکسان
- health check

**ردیابی تغییرات**
- بازبینی audit trail
- مستندسازی تغییرات مهم
- اطلاع‌رسانی به مصرف‌کنندگان

**مدیریت subscriptionها**
- بررسی سریع درخواست‌ها
- اطلاع‌رسانی تغییرات plan
- آرشیو APIهای غیرفعال

---

### Developer Portal

**بهبود discoverability**
- توضیح کوتاه و دقیق
- دسته و tag مرتبط
- لوگو
- quick start

**ارائه مثال**
- نمونه کد
- Postman collection
- use caseهای رایج

**تعامل با مصرف‌کنندگان**
- پاسخ به بازخورد
- پایش الگوهای مصرف
- کانال پشتیبانی

---

## عیب‌یابی

### مشکلات رایج

#### 401 Unauthorized

**علت‌های احتمالی**:
- API key نامعتبر/وجود ندارد
- JWT منقضی
- OAuth2 token نامعتبر
- subscription فعال نیست

**راه‌حل‌ها**:
1. وضعیت subscription را بررسی کنید
2. هدر/توکن را چک کنید
3. اعتبارنامه را renew کنید
4. تطابق نوع plan و روش احراز هویت را بررسی کنید

#### 429 Too Many Requests

**علت**: عبور از rate limit

**راه‌حل‌ها**:
1. هدرهای rate limit را بررسی کنید:
   - `X-RateLimit-Limit`
   - `X-RateLimit-Remaining`
   - `X-RateLimit-Reset`
2. backoff نمایی
3. درخواست plan با quota بالاتر
4. بهینه‌سازی الگوی درخواست (cache/batch)

#### 503 Service Unavailable

**علت‌های احتمالی**:
- Backend down
- circuit breaker باز
- فشار روی gateway

**راه‌حل‌ها**:
1. وضعیت backend را بررسی کنید
2. لاگ‌های gateway
3. صبر تا بسته شدن circuit breaker
4. تماس با ادمین

#### نمایش داده نشدن API در Portal

**علت‌های احتمالی**:
- منتشر نشده
- private و کاربر دسترسی ندارد
- deploy نشده

**راه‌حل‌ها**:
1. Published to Portal را چک کنید
2. portal visibility را چک کنید
3. deploy بودن را چک کنید
4. دسترسی گروه‌ها را بررسی کنید

#### طولانی شدن Pending subscription

**علت**: نیاز به تأیید دستی

**راه‌حل‌ها**:
1. تماس با مالک API
2. اطلاعات درخواست را کامل کنید
3. وضعیت اعلان ایمیل را بررسی کنید

---

### نکات دیباگ

**Debug Mode (برای v2)**:
1. API → Debug Mode را فعال کنید
2. درخواست تست بزنید
3. اجرای دقیق flow را بررسی کنید
4. بعد از پایان غیرفعال کنید (روی عملکرد اثر دارد)

**Request Logها**
- موقتاً logging را فعال کنید
- فیلتر کنید
- ترتیب اجرای policyها را بررسی کنید
- تبدیل‌های request/response را چک کنید

**تست policyها به‌صورت مرحله‌ای**
- یک‌به‌یک اضافه کنید
- بعد از هر تغییر تست کنید

**بررسی اتصال به Backend**
- backend URL را مستقیم تست کنید
- دسترسی شبکه gateway
- فایروال
- گواهی‌ها برای HTTPS

---

## واژه‌نامه

**API**: رابط برنامه‌نویسی کاربردی برای دسترسی به سرویس‌ها

**Application**: نرم‌افزار کلاینت مصرف‌کننده API

**Backend**: سرویس بالادستی که API به آن پراکسی می‌کند

**Circuit Breaker**: سیاست جلوگیری از شکست آبشاری با Fail Fast

**Context Path**: مسیری که API از طریق آن روی Gateway قابل دسترسی است

**CORS**: مکانیزم امنیت مرورگر برای درخواست‌های cross-domain

**Endpoint**: در v4، منبع Backend (Kafka/REST/MQTT و …)

**Entrypoint**: در v4، پروتکل دسترسی مصرف‌کننده (HTTP/WebSocket/SSE/Webhook)

**Flow**: زنجیره اجرای policyها

**Gateway**: مؤلفه Runtime که درخواست‌ها را مدیریت و policyها را اعمال می‌کند

**JWT**: توکن JSON Web Token برای احراز هویت/اطلاعات

**OAuth2**: چارچوب مجوزدهی استاندارد

**Plan**: تعریف روش دسترسی و احراز هویت

**Policy**: قانون پردازشی روی request/response

**Publisher**: توسعه‌دهنده/ناشر API

**QoS**: تضمین تحویل پیام در APIهای رویدادمحور

**Rate Limit**: محدودیت تعداد درخواست در بازه زمانی

**Subscription**: اتصال Application به Plan و دریافت اعتبارنامه

**v2 API**: تعریف سنتی پراکسی HTTP-to-HTTP

**v4 API**: تعریف پیشرفته با میانجی‌گری پروتکل و الگوهای رویدادمحور

---

## منابع تکمیلی

### مستندات
- مستندات رسمی Gravitee: https://documentation.gravitee.io/apim
- API Reference: بخش Documentation هر API
- Community Forum: انجمن Gravitee

### پشتیبانی
- GitHub Issues: گزارش باگ و درخواست ویژگی
- Slack/Discord جامعه: پشتیبانی real-time
- پشتیبانی سازمانی: برای مشتریان دارای لایسنس

### یادگیری
- وبلاگ Gravitee
- ویدئوهای آموزشی
- پروژه‌های نمونه

---

## پیوست: راهنمای سریع مرجع Policy

### Policyهای امنیتی

| Policy | کاربرد | پیکربندی |
|--------|--------|----------|
| API Key | احراز هویت ساده | Auto-validation، rate limit |
| OAuth2 | دسترسی ثالث | auth server، token endpoint |
| JWT | احراز هویت توکنی | public key، issuer، claims |
| mTLS | احراز هویت گواهی | CAهای مورد اعتماد، validation |
| Basic Auth | نام کاربری/رمز عبور | اعتبارسنجی credential |
| IP Filtering | محدودیت شبکه | whitelist/blacklist |

### Policyهای تبدیل

| Policy | کاربرد | پیکربندی |
|--------|--------|----------|
| JSON to JSON | تبدیل ساختار | JOLT |
| JSON to XML | تبدیل فرمت | root element |
| XML to JSON | تبدیل فرمت | namespace handling |
| Transform Headers | تغییر هدر | قوانین add/remove/update |
| URL Rewriting | تغییر مسیر | regex |

### Policyهای مدیریت ترافیک

| Policy | کاربرد | پیکربندی |
|--------|--------|----------|
| Rate Limit | throttle | limit، time unit، scope |
| Quota | محدودیت بلندمدت | limit، period |
| Circuit Breaker | تحمل خطا | threshold، timeout |
| Cache | کش پاسخ | TTL، cache key |
| Retry | تلاش مجدد | max attempts، backoff |

### Policyهای اعتبارسنجی

| Policy | کاربرد | پیکربندی |
|--------|--------|----------|
| JSON Validation | اعتبارسنجی schema | JSON Schema |
| XML Validation | اعتبارسنجی schema | XSD |
| Request Validation | اعتبارسنجی OpenAPI | OAS |

---

**پایان راهنمای کاربری**

---

## اطلاعات سند

**عنوان سند**: گراویتی مدیریت API - راهنمای کاربری  
**نسخه**: 1.0  
**پلتفرم هدف**: Gravitee APIM 4.x (Self-Hosted)  
**مخاطب**: توسعه‌دهندگان و ناشران API  
**آخرین به‌روزرسانی**: 2024

این مستندات بر راهنمای عملی و مبتنی بر جریان کاری برای استفاده از Gravitee APIM در محیط‌های Self-Hosted تمرکز دارد. برای نصب/راه‌اندازی، زیرساخت و ویژگی‌های مخصوص Cloud به مستندات رسمی Gravitee مراجعه کنید.