# Gravitee API Management - User Guide

## Introduction

This guide provides comprehensive, step-by-step instructions for using Gravitee API Management (APIM) in a self-hosted environment. It focuses on practical workflows and use cases for API developers and publishers.

### What is Gravitee APIM?

Gravitee APIM is a lightweight and performant API management platform that enables you to:
- Create, secure, and publish APIs (REST, GraphQL, WebSocket, event-driven)
- Control and measure API consumption
- Apply policies for security, transformation, and traffic management
- Monitor API performance and usage
- Provide a centralized Developer Portal for API consumers

### About This Guide

This documentation covers:
- **Audience**: API Developers and Publishers
- **Deployment**: Self-hosted environments only (cloud-specific features excluded)
- **Focus**: How to use the product (not installation/setup)
- **Coverage**: All API types (REST, event-driven, WebSocket, GraphQL, etc.)

---

## Core Concepts

Before diving into workflows, understand these key concepts:

### APIs in Gravitee

**v2 APIs**: Traditional HTTP proxy APIs that route requests from consumers to backend services. Best for simple REST API proxying.

**v4 APIs**: Advanced APIs supporting protocol mediation, allowing you to decouple consumer protocols (HTTP, WebSocket, SSE, Webhook) from backend protocols (REST, Kafka, MQTT, Solace, etc.).

### Entrypoints vs Endpoints

**Entrypoints**: How consumers access your API (HTTP GET, HTTP POST, WebSocket, Server-Sent Events, Webhook)

**Endpoints**: Your backend services or data sources (REST APIs, Kafka topics, MQTT brokers, Solace, RabbitMQ, etc.)

### Plans

Plans define how consumers can access your API and what security/authentication methods are required:
- **Keyless**: No authentication (public access)
- **API Key**: Simple token-based authentication
- **OAuth2**: Standards-based authorization framework
- **JWT**: JSON Web Token validation
- **mTLS**: Mutual TLS certificate-based authentication

### Policies

Policies are processing rules applied to API requests and responses. They handle:
- Security (authentication, authorization, validation)
- Transformation (JSON/XML conversion, data mapping)
- Traffic management (rate limiting, circuit breakers, caching)
- Logging and monitoring

### Applications

Applications represent client software that consumes your APIs. Developers create applications and subscribe them to API plans to obtain access credentials.

### Subscriptions

Subscriptions link applications to API plans. When a developer subscribes an application to an API, they receive credentials (like API keys) to access that API.

---

## Workflow 1: Creating Your First REST API (v2)

This workflow walks you through creating a simple REST API proxy using v2 APIs.

### When to Use v2 APIs

Use v2 APIs when you need:
- Simple HTTP-to-HTTP proxying
- Traditional REST API management
- Request/response-level policy enforcement
- Straightforward backend proxy without protocol mediation

### Step-by-Step: Create a v2 API

#### 1. Access the API Creation Wizard

1. Log into the Gravitee APIM Management Console
2. Navigate to **APIs** in the main menu
3. Click **+ Add API** or **Create API**
4. Select **v2 API** from the options

#### 2. Configure General Settings

Provide basic API information:
- **Name**: Your API's display name (e.g., "Products API")
- **Version**: API version identifier (e.g., "1.0")
- **Description**: Clear description of what your API does
- **Context Path**: The URL path where your API will be accessible (e.g., `/products`)

**Example**:
```
Name: Products API
Version: 1.0
Description: Provides access to product catalog information
Context Path: /products
```

#### 3. Configure Proxy Settings

Set up your backend endpoint:
- **Backend URL**: The actual backend service URL (e.g., `https://api.example.com/products`)
- **HTTP Methods**: Select which HTTP methods to expose (GET, POST, PUT, DELETE, etc.)

**Example**:
```
Backend URL: https://api.example.com/products
Methods: GET, POST, PUT, DELETE
```

#### 4. Configure Load Balancing (Optional)

If you have multiple backend instances:
1. Click **Add Endpoint** to add additional backend servers
2. Select a **Load Balancing Algorithm**:
   - Round Robin
   - Random
   - Weighted Round Robin

**Example**:
```
Endpoint 1: https://api1.example.com/products (Weight: 70%)
Endpoint 2: https://api2.example.com/products (Weight: 30%)
Algorithm: Weighted Round Robin
```

#### 5. Configure Health Checks (Optional)

Enable health checks to monitor backend availability:
1. Enable **Health Check**
2. Configure:
   - **Interval**: How often to check (e.g., 30 seconds)
   - **Endpoint**: Health check path (e.g., `/health`)
   - **Success Threshold**: Consecutive successful checks required

**Example**:
```
Enabled: Yes
Interval: 30s
Path: /health
Method: GET
Success Threshold: 2
```

#### 6. Set User and Group Access

Control who can manage this API:
1. Navigate to **User and Group Access**
2. Add users or groups with appropriate roles:
   - **Primary Owner**: Full control
   - **Owner**: Manage API settings
   - **User**: View only

#### 7. Save and Deploy

1. Click **Save** to create the API
2. Click **Deploy** to make it available on the gateway
3. Note the deployment status indicator

**Your API is now created but not yet accessible to consumers. Continue to add security plans.**

---

## Workflow 2: Creating Advanced APIs (v4)

v4 APIs offer advanced capabilities including protocol mediation and event-driven architectures.

### When to Use v4 APIs

Use v4 APIs when you need:
- Protocol mediation (e.g., HTTP consumers accessing Kafka backends)
- Event-driven API patterns
- WebSocket, Server-Sent Events, or Webhook support
- Message-level policy enforcement
- Asynchronous API capabilities

### Step-by-Step: Create a v4 API

#### 1. Access the v4 API Creation Wizard

1. Log into the APIM Management Console
2. Navigate to **APIs**
3. Click **+ Add API**
4. Select **v4 API**

#### 2. Configure General Settings

Same as v2 APIs:
- **Name**: API display name
- **Version**: Version identifier
- **Description**: API description
- **Context Path**: URL path for API access

#### 3. Define Entrypoints

Choose how consumers will access your API:

**HTTP GET**
- Suitable for: Read-only REST operations
- Use case: Polling data, retrieving resources

**HTTP POST**
- Suitable for: Full HTTP operations (bidirectional)
- Use case: CRUD operations, synchronous requests

**Server-Sent Events (SSE)**
- Suitable for: Unidirectional server-to-client streaming
- Use case: Real-time updates, notifications

**WebSocket**
- Suitable for: Full-duplex persistent connections
- Use case: Real-time bidirectional communication, chat applications

**Webhook**
- Suitable for: Event-driven HTTP callbacks
- Use case: Asynchronous event notifications

**Example Configuration**:
```
Selected Entrypoints:
- HTTP POST (for synchronous access)
- WebSocket (for real-time updates)

HTTP POST Configuration:
  Context Path: /api/events

WebSocket Configuration:
  Context Path: /ws/events
```

#### 4. Select Endpoints (Backends)

Choose your backend service type:

**REST API**
- Standard HTTP backend
- Configuration: Backend URL, HTTP methods

**Kafka**
- Kafka topic integration
- Configuration: Bootstrap servers, topics, consumer/producer settings

**MQTT5**
- IoT protocol support
- Configuration: MQTT broker, topics, QoS settings

**Solace**
- Enterprise event broker
- Configuration: Solace broker URL, queues, topics

**RabbitMQ**
- Message queue integration
- Configuration: RabbitMQ host, exchange, routing key

**Mock**
- Testing and development
- Configuration: Mock response configuration

**Azure Service Bus**
- Cloud messaging integration
- Configuration: Connection string, queue/topic name

**Example Configuration**:
```
Selected Endpoint: Kafka

Configuration:
  Bootstrap Servers: kafka1.example.com:9092,kafka2.example.com:9092
  Topics: user-events, order-events
  Consumer Group: apim-consumers
  Auto Offset Reset: earliest
```

#### 5. Configure Quality of Service (QoS)

For event-driven APIs, configure message delivery guarantees:
- **None**: No guarantee (fire and forget)
- **Auto**: Acknowledgment sent when message is received
- **At-Most-Once**: Message delivered once or lost
- **At-Least-Once**: Message guaranteed delivery (may duplicate)

#### 6. Apply Policies (Initial)

Add essential policies:
1. Click **Policy Studio**
2. Add basic policies (more details in Workflow 4)
3. Click **Save**

#### 7. Save and Deploy

1. Click **Save**
2. Click **Deploy** to activate the API on the gateway

**Your v4 API is now created. Next, add security plans to control access.**

---

## Workflow 3: Securing Your APIs with Plans

Plans control how developers access your APIs and what authentication is required.

### Understanding Plan Types

#### Keyless Plan
**Use Case**: Public APIs with no authentication
**Security**: None
**When to Use**:
- Public data APIs
- Testing/development environments
- APIs with no sensitive data

**Configuration Steps**:
1. Navigate to your API
2. Go to **Plans** → **Add Plan**
3. Select **Keyless**
4. Configure:
   - **Name**: e.g., "Public Access"
   - **Description**: "Unrestricted public access"
   - **Rate Limiting** (optional): Add to prevent abuse
5. Click **Save** and **Publish**

**Example**:
```
Plan Name: Public Access
Type: Keyless
Rate Limit: 1000 requests per minute
Auto-validation: Yes (subscriptions auto-approved)
```

---

#### API Key Plan
**Use Case**: Simple authentication with subscriber tracking
**Security**: Medium
**When to Use**:
- Internal APIs
- Partner integrations
- APIs requiring usage tracking

**Configuration Steps**:
1. Navigate to your API
2. Go to **Plans** → **Add Plan**
3. Select **API Key**
4. Configure:
   - **Name**: e.g., "Standard Access"
   - **Description**: API access with key authentication
   - **Auto-validation**: Choose whether subscriptions require approval
   - **Rate Limiting**: Set appropriate limits
5. Click **Save** and **Publish**

**How It Works**:
- Developers subscribe to your API and receive an API key
- They include the key in requests:
  - Header: `X-Gravitee-Api-Key: {api-key}`
  - Query parameter: `?api-key={api-key}`

**Example Configuration**:
```
Plan Name: Standard Access
Type: API Key
Auto-validation: No (requires manual approval)
Rate Limit: 5000 requests per day
Quota: 100,000 requests per month
```

**Example API Call**:
```bash
curl -X GET "https://gateway.example.com/products" \
  -H "X-Gravitee-Api-Key: a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
```

---

#### OAuth2 Plan
**Use Case**: Delegated authorization, third-party access
**Security**: High
**When to Use**:
- Public-facing APIs
- Third-party integrations
- Applications requiring user consent

**Configuration Steps**:
1. Navigate to your API
2. Go to **Plans** → **Add Plan**
3. Select **OAuth2**
4. Configure:
   - **Name**: e.g., "OAuth2 Access"
   - **Authorization Server**:
     - Generic OAuth2 server
     - Gravitee.io Access Management (if installed)
   - **Token Endpoint**: OAuth2 token endpoint URL
   - **Introspection Endpoint**: Token validation endpoint
   - **Scopes**: Define required scopes (e.g., `read:products`, `write:products`)
5. Click **Save** and **Publish**

**Example Configuration**:
```
Plan Name: OAuth2 Access
Type: OAuth2
Authorization Server: https://auth.example.com
Token Endpoint: https://auth.example.com/oauth/token
Introspection Endpoint: https://auth.example.com/oauth/introspect
Required Scopes: read:products, write:products
Client Authentication: Required
```

**How It Works**:
1. Developer registers application and receives client credentials
2. Application obtains access token from authorization server
3. Application includes token in API requests:
   ```bash
   curl -X GET "https://gateway.example.com/products" \
     -H "Authorization: Bearer {access-token}"
   ```

---

#### JWT Plan
**Use Case**: Token-based authentication with existing JWT infrastructure
**Security**: High
**When to Use**:
- Microservices architectures
- Internal APIs with existing JWT auth
- APIs requiring stateless authentication

**Configuration Steps**:
1. Navigate to your API
2. Go to **Plans** → **Add Plan**
3. Select **JWT**
4. Configure:
   - **Name**: e.g., "JWT Access"
   - **Signature Verification**:
     - **Public Key**: Provide RSA/EC public key for verification
     - **JWKS URL**: URL to JSON Web Key Set
     - **Shared Secret**: For HMAC signatures
   - **Issuer**: Expected `iss` claim value
   - **Claims Validation**: Required claims and values
5. Click **Save** and **Publish**

**Example Configuration**:
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

**Example API Call**:
```bash
curl -X GET "https://gateway.example.com/products" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

#### mTLS Plan
**Use Case**: Certificate-based mutual authentication
**Security**: Very High
**When to Use**:
- B2B integrations
- Highly sensitive APIs
- Environments requiring certificate-based security

**Configuration Steps**:
1. Navigate to your API
2. Go to **Plans** → **Add Plan**
3. Select **mTLS**
4. Configure:
   - **Name**: e.g., "Certificate Access"
   - **Client Certificate Requirement**: Required or optional
   - **Certificate Chain Validation**: Enable to validate full chain
   - **Trusted CAs**: Upload trusted Certificate Authority certificates
5. Click **Save** and **Publish**

**Example Configuration**:
```
Plan Name: Certificate Access
Type: mTLS
Client Certificate: Required
Certificate Chain Validation: Enabled
Trusted CAs: [Upload CA certificate]
Certificate Subject DN Validation: CN=*.example.com
```

**How It Works**:
- Client presents certificate during TLS handshake
- Gateway validates certificate against trusted CAs
- Only valid certificate holders can access the API

---

### Publishing Plans

After creating plans:
1. Review plan configuration
2. Click **Publish** to make the plan available
3. Plans must be published before developers can subscribe

---

## Workflow 4: Applying Policies

Policies add functionality to your APIs for security, transformation, traffic management, and more.

### Understanding Policy Studio

Policy Studio is where you build request/response processing flows by adding and configuring policies.

**Key Concepts**:
- **Flows**: Processing chains where policies execute
- **Phases**: Request phase (before backend) and Response phase (after backend)
- **Conditions**: Execute policies based on conditions (path, headers, etc.)

### Accessing Policy Studio

1. Navigate to your API
2. Select **Policy Studio** from the menu
3. Choose the flow type:
   - **Request Flow**: Policies executed on incoming requests
   - **Response Flow**: Policies executed on outgoing responses
   - **Publish Flow**: Policies for message publication (v4 APIs)
   - **Subscribe Flow**: Policies for message consumption (v4 APIs)

---

### Common Policy Use Cases

#### Use Case 1: Add Rate Limiting

Prevent API abuse by limiting request rates.

**Steps**:
1. Open **Policy Studio**
2. In the **Request Flow**, click **+ Add Policy**
3. Select **Rate Limit** policy
4. Configure:
   - **Rate Limit Type**:
     - **Per Consumer**: Limit per API key/subscription
     - **Per API**: Global limit for entire API
   - **Limit**: Number of requests
   - **Time Unit**: Second, minute, hour, or day
   - **Key**: Identifier for rate limiting (default: subscription ID)
5. Click **Save**
6. Click **Deploy API**

**Example Configuration**:
```
Policy: Rate Limit
Type: Per Consumer
Limit: 1000 requests per minute
Async: No
Add Headers: Yes (X-RateLimit-Limit, X-RateLimit-Remaining)
```

**Result**: Each consumer can make 1000 requests per minute. Exceeding this returns `429 Too Many Requests`.

---

#### Use Case 2: Transform JSON Responses

Modify response data structure or content.

**Steps**:
1. Open **Policy Studio**
2. In the **Response Flow**, click **+ Add Policy**
3. Select **JSON to JSON** transformation policy
4. Configure transformation specification:
   - Use JOLT specification for complex transformations
   - Use simple key mapping for basic changes
5. Click **Save**
6. Click **Deploy API**

**Example Configuration**:
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

**Before**:
```json
{
  "data": [
    {"id": 1, "name": "Widget", "price": 9.99},
    {"id": 2, "name": "Gadget", "price": 19.99}
  ]
}
```

**After**:
```json
{
  "items": [
    {"productId": 1, "productName": "Widget", "cost": 9.99},
    {"productId": 2, "productName": "Gadget", "cost": 19.99}
  ]
}
```

---

#### Use Case 3: Add Request Logging

Log requests for debugging and auditing.

**Steps**:
1. Open **Policy Studio**
2. In the **Request Flow**, click **+ Add Policy**
3. Select **Logging** policy (or use platform-level logging)
4. Configure:
   - **Scope**: Request, response, or both
   - **Mode**: Client and proxy
   - **Content**: Include payload or headers only
5. Click **Save**
6. Click **Deploy API**

**Example Configuration**:
```
Policy: Logging
Scope: REQUEST and RESPONSE
Mode: CLIENT_PROXY
Content: Include headers and payload
```

**Note**: For production, use selective logging to avoid performance impact.

---

#### Use Case 4: Add CORS Support

Enable cross-origin requests from browsers.

**Steps**:
1. Navigate to your API
2. Go to **Proxy** → **CORS**
3. Enable CORS
4. Configure:
   - **Allowed Origins**: Domains allowed to access API (e.g., `https://app.example.com`)
   - **Allowed Methods**: HTTP methods (GET, POST, PUT, DELETE, OPTIONS)
   - **Allowed Headers**: Request headers (e.g., `Content-Type, Authorization`)
   - **Exposed Headers**: Response headers visible to browser
   - **Max Age**: Preflight cache duration (seconds)
5. Click **Save**
6. Click **Deploy API**

**Example Configuration**:
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

#### Use Case 5: Validate Request Payload

Ensure incoming data matches expected schema.

**Steps**:
1. Open **Policy Studio**
2. In the **Request Flow**, click **+ Add Policy**
3. Select **JSON Validation** policy
4. Configure:
   - **JSON Schema**: Provide JSON Schema for validation
   - **Error Message**: Custom error message for validation failures
   - **Status Code**: HTTP status code for failures (default: 400)
5. Click **Save**
6. Click **Deploy API**

**Example Configuration**:
```
Policy: JSON Validation
Schema:
{
  "type": "object",
  "properties": {
    "name": {"type": "string", "minLength": 1},
    "email": {"type": "string", "format": "email"},
    "age": {"type": "integer", "minimum": 0}
  },
  "required": ["name", "email"]
}
Error Message: Invalid request payload
Status Code: 400
```

---

#### Use Case 6: Add Circuit Breaker

Prevent cascading failures when backend is unhealthy.

**Steps**:
1. Open **Policy Studio**
2. In the **Request Flow**, click **+ Add Policy**
3. Select **Circuit Breaker** policy
4. Configure:
   - **Failure Threshold**: Number of failures before opening circuit
   - **Timeout**: Time to wait before retry (seconds)
   - **Success Threshold**: Successful requests needed to close circuit
5. Click **Save**
6. Click **Deploy API**

**Example Configuration**:
```
Policy: Circuit Breaker
Failure Threshold: 5 failures
Timeout: 30 seconds
Success Threshold: 3 successful requests
```

**How It Works**:
1. **Closed State**: Normal operation
2. **Open State**: After 5 failures, circuit opens, requests fail fast
3. **Half-Open State**: After 30s, allows 3 test requests
4. **Closed State**: If tests succeed, circuit closes

---

### Policy Categories Reference

#### Security Policies
- API Key
- OAuth2
- JWT
- Basic Authentication
- mTLS
- SSL Enforcement
- IP Filtering
- LDAP Authentication

#### Transformation Policies
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
- Groovy Script (custom transformations)

#### Traffic Management Policies
- Rate Limit
- Quota
- Spike Arrest
- Circuit Breaker
- Retry
- Timeout
- Cache
- Traffic Shadowing

#### Routing Policies
- Dynamic Routing
- Request Validation
- Mock Response

#### Monitoring Policies
- Logging
- Metrics Reporter
- Custom Metrics

---

## Workflow 5: Publishing APIs to Developer Portal

Make your APIs discoverable and accessible to developers.

### Step-by-Step: Publish an API

#### 1. Complete API Configuration

Ensure your API has:
- At least one published plan
- Complete API documentation
- Proper naming and description

#### 2. Add API Documentation

1. Navigate to your API
2. Go to **Documentation**
3. Click **+ Add Documentation**
4. Choose documentation type:
   - **OpenAPI/Swagger**: Import OpenAPI specification
   - **AsyncAPI**: For event-driven APIs
   - **Markdown**: Custom documentation
   - **AsciiDoc**: Structured documentation
5. Upload or paste your documentation
6. Click **Save**

**Example OpenAPI Import**:
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

#### 3. Configure API Metadata

1. Go to **Info** or **General Settings**
2. Add:
   - **Categories**: Group APIs by function (e.g., "E-commerce", "Analytics")
   - **Labels**: Tags for filtering (e.g., "public", "beta", "v1")
   - **Picture**: API icon or logo
3. Click **Save**

#### 4. Publish to Developer Portal

1. Navigate to **Deployment** or **Portal**
2. Toggle **Published to Portal** to ON
3. Click **Save**

**Your API is now visible in the Developer Portal!**

---

### Managing API Visibility

Control who can see your API:

**Public APIs**:
- Visible to all Developer Portal users
- Discoverable through search
- Plans may still require subscription

**Private APIs**:
- Visible only to specific groups
- Configure in **User and Group Access**
- Useful for internal or partner APIs

**Configuration**:
1. Go to **User and Group Access**
2. Under **Portal Visibility**, select:
   - **Public**: All users
   - **Private**: Selected groups only
3. If Private, add authorized groups
4. Click **Save**

---

## Workflow 6: Managing Applications and Subscriptions

### For API Publishers: Managing Subscription Requests

When developers subscribe to your API, you may need to approve requests.

#### View Subscription Requests

1. Navigate to your API
2. Go to **Subscriptions** → **Subscription Requests**
3. Review pending requests showing:
   - Application name
   - Plan requested
   - Developer/owner
   - Date requested

#### Approve or Reject Subscriptions

1. Click on a subscription request
2. Review application details:
   - Application description
   - Owner information
   - Intended use
3. Choose action:
   - **Accept**: Approve and activate subscription
   - **Reject**: Deny with optional reason
4. Enter message (optional)
5. Click **Confirm**

**Approved subscriptions**:
- Generate credentials (API keys for API Key plans)
- Activate immediately
- Developer receives notification

#### Manage Active Subscriptions

1. Go to **Subscriptions** → **Manage Subscriptions**
2. View all active subscriptions
3. Available actions:
   - **Pause**: Temporarily disable without deleting
   - **Resume**: Reactivate paused subscription
   - **Close**: Permanently terminate subscription
   - **Renew Keys**: Generate new API key (for API Key plans)
   - **Transfer**: Move subscription to different application

**To Close a Subscription**:
1. Select subscription
2. Click **Close**
3. Confirm action
4. Developer's access is immediately revoked

---

### For API Consumers: Creating Applications and Subscribing

This section appears in the Developer Portal workflows (see Workflow 9).

---

## Workflow 7: Monitoring and Analytics

Gravitee APIM provides comprehensive monitoring to track API performance and usage.

### Accessing Dashboards

#### API-Level Dashboard

1. Navigate to your API
2. Select **Analytics** or **Dashboard**
3. View metrics including:
   - **Request Count**: Total requests over time
   - **Response Times**: Average, min, max, percentiles (p50, p95, p99)
   - **Error Rates**: 4xx and 5xx error percentages
   - **Top Consumers**: Applications with highest usage
   - **Status Code Distribution**: Breakdown by HTTP status
   - **Geographic Distribution**: Requests by location (if enabled)

**Time Range Selection**:
- Last hour
- Last 24 hours
- Last 7 days
- Last 30 days
- Custom range

#### Platform-Wide Dashboard

1. From main menu, go to **Dashboard** or **Analytics**
2. View aggregated metrics across all APIs:
   - Total API calls
   - Response time trends
   - Error rates
   - Top APIs by traffic
   - Platform health status

---

### Viewing Request Logs

Detailed request/response logs help troubleshoot issues.

#### Enable Logging

1. Navigate to your API
2. Go to **Analytics** → **Logging**
3. Configure logging:
   - **Mode**:
     - **None**: No logging
     - **Client Only**: Log client requests/responses
     - **Proxy Only**: Log proxy to backend
     - **Client and Proxy**: Log both
   - **Content**: Include request/response payloads
   - **Sampling**: Log percentage of requests (e.g., 10%)
4. Click **Save** and **Deploy API**

**Warning**: Logging with content enabled impacts performance and storage. Use sampling in production.

#### View Logs

1. Go to **Analytics** → **Logs**
2. Filter logs by:
   - Time range
   - HTTP status code
   - Consumer application
   - Plan
3. Click on a log entry to see:
   - Request details (headers, payload, timestamp)
   - Response details (status, headers, payload)
   - Backend calls and timing
   - Policies executed
   - Errors or warnings

**Example Log Entry**:
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

### API Quality Scoring

Assess and improve API quality.

#### View API Quality Score

1. Navigate to **Analytics** → **API Quality** (may be under platform settings)
2. View quality metrics:
   - **Documentation Completeness**: API docs availability
   - **Logo/Image**: Visual identity
   - **Categories**: Proper categorization
   - **Labels**: Appropriate tagging
   - **Health Check**: Backend health monitoring
   - **Description Quality**: Complete, meaningful descriptions

**Quality Score**: 0-100% based on above factors

#### Improve Quality Score

1. Add comprehensive documentation
2. Configure health checks
3. Add API logo
4. Assign categories and labels
5. Write detailed descriptions
6. Publish API to portal

---

### Audit Trail

Track changes to APIs and platform configuration.

#### Access Audit Trail

1. From main menu, go to **Audit** or **Settings** → **Audit Trail**
2. View all changes including:
   - API created, updated, deployed
   - Plans published, closed
   - Subscriptions approved, rejected
   - User access changes
   - Configuration modifications

#### Filter Audit Events

- **By API**: Show events for specific API
- **By Event Type**: Create, update, delete, deploy
- **By User**: Show actions by specific user
- **By Date Range**: Filter by time period

**Example Audit Entry**:
```
Date: 2024-01-15 14:30:00
User: admin@example.com
Event: API_DEPLOYED
API: Products API (v1.0)
Details: Deployed API with Rate Limit policy updated
```

---

### Configuring Reporters

Export metrics to external systems.

#### Available Reporters

- **Elasticsearch**: Full-text search and analytics
- **File Reporter**: Write metrics to files
- **TCP Reporter**: Stream to TCP endpoint
- **Datadog**: Integration with Datadog monitoring

#### Configure Elasticsearch Reporter (Example)

1. Go to **Settings** → **Analytics** → **Reporters**
2. Click **+ Add Reporter**
3. Select **Elasticsearch**
4. Configure:
   - **Hosts**: Elasticsearch cluster URLs
   - **Index Name**: Index for metrics (e.g., `gravitee-metrics`)
   - **Index Mode**: Daily, weekly, monthly
   - **Authentication**: If required
5. Click **Save**

**Example Configuration**:
```
Reporter: Elasticsearch
Hosts: https://es1.example.com:9200, https://es2.example.com:9200
Index: gravitee-metrics
Index Mode: Daily (gravitee-metrics-2024-01-15)
Authentication: Basic (username/password)
SSL Verification: Enabled
```

---

### OpenTelemetry Integration

Integrate with OpenTelemetry for distributed tracing.

#### Enable OpenTelemetry

1. Go to **Settings** → **OpenTelemetry**
2. Enable OpenTelemetry
3. Configure:
   - **Endpoint**: OTLP endpoint URL
   - **Protocol**: gRPC or HTTP
   - **Service Name**: Identifier for this gateway
4. Click **Save**

**Example Configuration**:
```
Enabled: Yes
Endpoint: https://otel-collector.example.com:4317
Protocol: gRPC
Service Name: gravitee-apim-gateway
```

#### View Traces

- Use your OpenTelemetry backend (Jaeger, Zipkin, etc.)
- Traces show:
  - Request path through gateway
  - Policy execution times
  - Backend call duration
  - Total request latency

---

## Workflow 8: Advanced Use Cases

### Event-Driven APIs with Kafka

Expose Kafka topics as REST, WebSocket, or SSE APIs.

#### Use Case Example

**Scenario**: You have a Kafka topic `user-events` and want to expose it as:
- REST API for synchronous consumption
- WebSocket for real-time streaming

#### Step-by-Step: Create Kafka API

##### 1. Create v4 API

1. Go to **APIs** → **+ Add API**
2. Select **v4 API**
3. Configure general settings:
   - **Name**: User Events API
   - **Version**: 1.0
   - **Context Path**: `/user-events`

##### 2. Configure Entrypoints

Select multiple entrypoints:

**HTTP POST** (for single message retrieval):
```
Context Path: /user-events
Message Timeout: 5000ms (wait for message)
```

**WebSocket** (for streaming):
```
Context Path: /ws/user-events
Publisher: Disabled (consumer only)
```

##### 3. Configure Kafka Endpoint

1. Select **Kafka** endpoint
2. Configure connection:
```
Bootstrap Servers: kafka1.example.com:9092,kafka2.example.com:9092
Topics: user-events
Consumer Group: apim-user-events-consumers
Auto Offset Reset: latest
Initial Offset: EARLIEST or LATEST
Security Protocol: PLAINTEXT (or SASL_SSL for secure)
```

**For SASL Authentication**:
```
Security Protocol: SASL_SSL
SASL Mechanism: PLAIN (or SCRAM-SHA-256, SCRAM-SHA-512)
SASL Username: kafka-user
SASL Password: [password]
```

##### 4. Configure Quality of Service

```
QoS: Auto (acknowledgment sent when message received)
```

##### 5. Apply Policies

Add policies as needed:
- **API Key**: For authentication
- **Rate Limit**: Prevent abuse
- **JSON Validation**: Validate message format

##### 6. Create Plans

Create appropriate security plans (e.g., API Key plan)

##### 7. Deploy

1. Click **Save**
2. Click **Deploy**

#### Consuming the Kafka API

**REST API (HTTP POST)**:
```bash
# Poll for a single message
curl -X POST "https://gateway.example.com/user-events" \
  -H "X-Gravitee-Api-Key: your-api-key" \
  -H "Content-Type: application/json"

Response:
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

### WebSocket APIs

Create real-time bidirectional communication APIs.

#### Use Case Example

**Scenario**: Build a chat API with WebSocket support.

#### Step-by-Step: Create WebSocket API

##### 1. Create v4 API

1. Go to **APIs** → **+ Add API**
2. Select **v4 API**
3. Configure:
   - **Name**: Chat API
   - **Version**: 1.0
   - **Context Path**: `/chat`

##### 2. Configure WebSocket Entrypoint

1. Select **WebSocket** entrypoint
2. Configure:
```
Context Path: /ws/chat
Publisher: Enabled (bidirectional)
Subscriber: Enabled (bidirectional)
```

##### 3. Configure Backend Endpoint

Choose backend type:
- **WebSocket**: Proxy to another WebSocket server
- **Kafka/MQTT**: Message broker backend
- **Mock**: For testing

**Example - WebSocket Backend**:
```
Backend URL: wss://chat-backend.example.com/socket
```

##### 4. Apply Policies

- **JWT**: Authenticate WebSocket connections
- **Rate Limit**: Limit message rate

##### 5. Deploy

1. Click **Save**
2. Click **Deploy**

#### Connecting to WebSocket API

```javascript
const ws = new WebSocket('wss://gateway.example.com/ws/chat', {
  headers: {
    'Authorization': 'Bearer your-jwt-token'
  }
});

ws.onopen = () => {
  // Send message
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

### Shared Policy Groups

Reuse common policy combinations across multiple APIs.

#### Use Case Example

**Scenario**: You have 10 APIs that all need the same security and rate limiting policies.

#### Step-by-Step: Create Shared Policy Group

##### 1. Access Shared Policy Groups

1. Go to **Policies** → **Shared Policy Groups** (may be under Settings or Configuration)
2. Click **+ Create Policy Group**

##### 2. Configure Policy Group

1. Enter:
   - **Name**: Standard Security
   - **Description**: API Key + Rate Limit + CORS
   - **Phase**: Request
2. Click **Create**

##### 3. Add Policies to Group

1. In Policy Group editor, click **+ Add Policy**
2. Add policies in order:
   - **API Key**: Authentication
   - **Rate Limit**: 1000 req/min per consumer
   - **CORS**: Allow origins
3. Configure each policy
4. Click **Save**

##### 4. Apply to APIs

**Method 1: During API Creation**
- In Policy Studio, select **+ Add Shared Policy Group**
- Choose "Standard Security"

**Method 2: Existing APIs**
1. Navigate to API
2. Go to **Policy Studio**
3. Click **+ Add Shared Policy Group**
4. Select "Standard Security"
5. Click **Save** and **Deploy**

#### Benefits

- **Consistency**: Same policies across APIs
- **Maintainability**: Update once, applies to all
- **Efficiency**: Quick setup for new APIs

---

### API Import and Export

Migrate APIs between environments or backup configurations.

#### Export API

1. Navigate to your API
2. Go to **General** or **Settings**
3. Click **Export**
4. Choose format:
   - **JSON**: Full API definition
   - **Gravitee Definition**: Platform-specific format
5. Download file

**Export includes**:
- API configuration
- Plans
- Policies
- Documentation
- Resources

#### Import API

1. Go to **APIs**
2. Click **Import**
3. Upload API definition file
4. Review configuration:
   - Update context path if needed
   - Adjust backend URLs for target environment
5. Click **Import**
6. Update environment-specific settings
7. Deploy

**Note**: Update sensitive data (API keys, secrets, backend URLs) after import.

---

## Workflow 9: Developer Portal (For API Consumers)

This section describes the Developer Portal from the API consumer perspective.

### Accessing the Developer Portal

**Portal URL**: Typically `https://portal.example.com` (configured during setup)

1. Open Developer Portal URL in browser
2. Sign up or log in:
   - **Self-Registration**: If enabled, create account
   - **SSO**: Use organizational login
   - **Invitation**: Use invite link from API publisher

---

### Discovering APIs

#### Browse API Catalog

1. From Portal homepage, view API catalog
2. APIs displayed as cards showing:
   - API name and version
   - Description
   - Categories/labels
   - Owner/publisher
3. Use filters:
   - **Category**: Filter by API category
   - **Label**: Filter by tags
   - **Search**: Text search by name/description

#### View API Details

1. Click on an API card
2. View API details:
   - **Overview**: Description, version, owner
   - **Documentation**: API reference (OpenAPI, AsyncAPI, etc.)
   - **Plans**: Available subscription plans
   - **Versions**: API version history

#### Read API Documentation

1. In API details, click **Documentation** tab
2. View interactive API documentation:
   - Endpoints and operations
   - Request/response schemas
   - Example requests
3. **Try It**: Test API endpoints directly (if enabled)

**Example - Try an Endpoint**:
1. Select endpoint (e.g., `GET /products`)
2. Add parameters if required
3. Add authentication (if you have subscription)
4. Click **Execute**
5. View response

---

### Creating an Application

Applications represent your client software consuming APIs.

#### Step-by-Step: Create Application

1. From Portal menu, go to **Applications**
2. Click **+ Create Application**
3. Enter details:
   - **Name**: Your application name (e.g., "Mobile App")
   - **Description**: What your app does
   - **Type**:
     - **Browser**: Web applications
     - **Native**: Mobile/desktop apps
     - **Backend to Backend**: Server applications
     - **Web**: Traditional web apps
   - **Client ID**: Auto-generated (for OAuth2/JWT flows)
4. Click **Create**

**Example**:
```
Name: E-commerce Mobile App
Description: iOS and Android app for product browsing and ordering
Type: Native
Owner: developer@example.com
```

---

### Subscribing to APIs

Link your application to an API to obtain credentials.

#### Step-by-Step: Subscribe

1. Navigate to API details in Portal
2. Click **Subscribe** or **Create Subscription**
3. Select:
   - **Application**: Choose your application
   - **Plan**: Select subscription plan (e.g., "Standard Access")
4. Enter additional info if requested:
   - Reason for access
   - Intended use
5. Click **Subscribe** or **Request Subscription**

**Auto-Approved Plans**: Subscription activates immediately

**Manual Approval Required**:
- Request sent to API publisher
- Wait for approval notification
- Check subscription status in **My Subscriptions**

#### View Subscription Details

After approval:
1. Go to **Applications** → Your Application
2. Click **Subscriptions** tab
3. View active subscriptions showing:
   - API name
   - Plan
   - Status (Active, Paused, Pending)
   - **API Key** (for API Key plans)
   - Creation date
   - Usage statistics

**Example**:
```
API: Products API v1.0
Plan: Standard Access
Status: Active
API Key: a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d
Created: 2024-01-15
Quota: 50,000 / 100,000 requests (50%)
```

---

### Using API Credentials

#### API Key Plans

Copy API key from subscription and include in requests:

**Header Method** (recommended):
```bash
curl -X GET "https://gateway.example.com/products" \
  -H "X-Gravitee-Api-Key: a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
```

**Query Parameter Method**:
```bash
curl -X GET "https://gateway.example.com/products?api-key=a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
```

#### OAuth2 Plans

1. Use application Client ID and Client Secret
2. Obtain access token from authorization server
3. Include token in API requests:

```bash
# Get access token
curl -X POST "https://auth.example.com/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=your-client-id" \
  -d "client_secret=your-client-secret" \
  -d "scope=read:products"

# Use token
curl -X GET "https://gateway.example.com/products" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

### Monitoring Application Usage

Track your application's API consumption.

#### View Usage Analytics

1. Go to **Applications** → Your Application
2. Click **Analytics** or **Dashboard**
3. View metrics:
   - **Request Count**: Calls over time
   - **Response Times**: Performance metrics
   - **Error Rates**: Failed requests
   - **Quota Usage**: Remaining quota
   - **By API**: Breakdown per subscribed API

#### View Logs

1. In your application, go to **Logs**
2. Filter by:
   - API
   - Date range
   - Status code
3. View request/response details (if logging enabled by API publisher)

---

### Managing Subscriptions

#### Renew API Keys

If API key is compromised:
1. Go to **Applications** → Your Application → **Subscriptions**
2. Select subscription
3. Click **Renew Key** or **Regenerate**
4. Confirm action
5. Update your application with new key
6. Old key is immediately invalidated

#### Cancel Subscription

1. Go to subscription details
2. Click **Cancel** or **Unsubscribe**
3. Confirm cancellation
4. Access is immediately revoked

---

### Managing Application Settings

#### Update Application Details

1. Go to **Applications** → Your Application
2. Click **Settings** or **Edit**
3. Update:
   - Name
   - Description
   - Type
   - Callback URLs (for OAuth2)
4. Click **Save**

#### Manage Application Members

Add team members to your application:
1. Go to **Applications** → Your Application
2. Click **Members** or **Team**
3. Click **+ Add Member**
4. Enter email and select role:
   - **Owner**: Full control
   - **User**: View only
5. Click **Add**

---

## Best Practices

### API Design

**Use Consistent Naming**
- Context paths: lowercase, hyphen-separated (`/user-management`)
- API names: Clear and descriptive
- Versions: Semantic versioning (1.0, 1.1, 2.0)

**Version Your APIs**
- Include version in context path (`/v1/products`) or as header
- Maintain backward compatibility when possible
- Document breaking changes

**Document Thoroughly**
- Provide OpenAPI/Swagger specifications
- Include examples for all endpoints
- Document error codes and responses
- Update docs with API changes

---

### Security

**Use Appropriate Plan Types**
- Public data: Keyless (with rate limiting)
- Internal APIs: API Key
- Third-party integrations: OAuth2
- High-security: mTLS or JWT

**Apply Rate Limiting**
- Prevent abuse and ensure fair usage
- Set appropriate limits per plan tier
- Monitor and adjust based on usage patterns

**Validate Input**
- Use JSON/XML validation policies
- Validate request schemas
- Sanitize user input

**Encrypt Sensitive Data**
- Use HTTPS for all APIs
- Don't log sensitive information
- Rotate credentials regularly

---

### Performance

**Enable Caching**
- Cache frequently accessed, rarely changing data
- Set appropriate TTL values
- Use cache policies for GET requests

**Configure Health Checks**
- Monitor backend availability
- Use circuit breakers for failing backends
- Implement retry policies with backoff

**Optimize Logging**
- Use sampling in production (log 10-20% of requests)
- Avoid logging large payloads
- Use appropriate log levels

**Monitor Response Times**
- Set performance budgets
- Identify slow endpoints
- Optimize backend services

---

### Governance

**Use Categories and Labels**
- Organize APIs by domain/function
- Tag APIs by lifecycle stage (beta, stable, deprecated)
- Use labels for filtering and discovery

**Implement Quality Standards**
- Aim for high quality scores
- Require complete documentation
- Use consistent naming conventions
- Configure health checks

**Track Changes**
- Review audit trail regularly
- Document major changes
- Communicate API updates to consumers

**Manage Subscriptions**
- Review subscription requests promptly
- Communicate plan changes
- Archive inactive APIs

---

### Developer Portal

**Optimize Discoverability**
- Write clear, concise API descriptions
- Use relevant categories and tags
- Add API logos/images
- Provide quick start guides

**Provide Examples**
- Include code samples for popular languages
- Provide Postman collections
- Document common use cases

**Engage Consumers**
- Respond to feedback
- Monitor API usage patterns
- Provide support channels

---

## Troubleshooting

### Common Issues

#### API Returns 401 Unauthorized

**Possible Causes**:
- Missing or invalid API key
- Expired JWT token
- Invalid OAuth2 token
- Subscription not active

**Solutions**:
1. Verify subscription is active
2. Check API key/token in request headers
3. Renew expired credentials
4. Verify plan type matches authentication method

#### API Returns 429 Too Many Requests

**Cause**: Rate limit exceeded

**Solutions**:
1. Check rate limit headers:
   - `X-RateLimit-Limit`: Maximum requests
   - `X-RateLimit-Remaining`: Remaining requests
   - `X-RateLimit-Reset`: Reset timestamp
2. Implement exponential backoff
3. Request higher quota plan
4. Optimize request patterns (caching, batching)

#### API Returns 503 Service Unavailable

**Possible Causes**:
- Backend service down
- Circuit breaker open
- Gateway overloaded

**Solutions**:
1. Check backend health status
2. Review gateway logs
3. Wait for circuit breaker to close (half-open state)
4. Contact API administrator

#### API Not Appearing in Developer Portal

**Possible Causes**:
- API not published to portal
- User doesn't have access (private API)
- API not deployed

**Solutions**:
1. Verify API is published (Deployment → Published to Portal)
2. Check portal visibility settings
3. Ensure API is deployed
4. Verify user group access

#### Subscription Pending for Long Time

**Cause**: Manual approval required, publisher hasn't reviewed

**Solutions**:
1. Contact API owner/administrator
2. Check subscription request includes all required info
3. Verify email notifications are working

---

### Debugging Tips

**Enable Debug Mode** (v2 APIs):
1. Go to your API
2. Enable **Debug Mode**
3. Make test requests
4. Review detailed execution flow
5. Disable when done (impacts performance)

**Use Request Logs**:
- Enable logging temporarily
- Filter by status code or time range
- Review policy execution order
- Check request/response transformations

**Test Policies Individually**:
- Add policies one at a time
- Test after each addition
- Isolate problematic policies

**Check Backend Connectivity**:
- Test backend URL directly
- Verify network access from gateway
- Check firewall rules
- Validate certificates (for HTTPS backends)

---

## Glossary

**API**: Application Programming Interface - a programmatic interface for accessing services

**Application**: A client software application that consumes APIs

**Backend**: The upstream service or data source that an API proxies to

**Circuit Breaker**: A policy that prevents cascading failures by failing fast when backend is unhealthy

**Context Path**: The URL path where an API is accessible on the gateway

**CORS**: Cross-Origin Resource Sharing - browser security mechanism for cross-domain requests

**Endpoint**: In v4 APIs, the backend service or data source (Kafka, REST, MQTT, etc.)

**Entrypoint**: In v4 APIs, the protocol consumers use to access the API (HTTP, WebSocket, SSE, Webhook)

**Flow**: A processing chain where policies execute in order

**Gateway**: The runtime component that handles API requests and enforces policies

**JWT**: JSON Web Token - a token format for authentication and information exchange

**OAuth2**: An authorization framework for delegated access

**Plan**: Defines how consumers can access an API and what authentication is required

**Policy**: A processing rule applied to API requests or responses

**Publisher**: An API developer who creates and publishes APIs

**QoS**: Quality of Service - message delivery guarantees for event-driven APIs

**Rate Limit**: A limit on the number of requests allowed in a time period

**Subscription**: Links an application to an API plan, providing access credentials

**v2 API**: Traditional API definition for HTTP-to-HTTP proxying

**v4 API**: Advanced API definition supporting protocol mediation and event-driven patterns

---

## Additional Resources

### Documentation
- Official Gravitee Documentation: https://documentation.gravitee.io/apim
- API Reference: Check your API's documentation section
- Community Forum: Gravitee Community

### Support
- GitHub Issues: Report bugs and feature requests
- Community Slack/Discord: Real-time community support
- Enterprise Support: Available for licensed customers

### Learning
- Gravitee Blog: Best practices and use cases
- Video Tutorials: Platform walkthroughs
- Sample Projects: Example API configurations

---

## Appendix: Policy Reference Quick Guide

### Security Policies

| Policy | Use Case | Configuration |
|--------|----------|---------------|
| API Key | Simple authentication | Auto-validation, rate limits |
| OAuth2 | Third-party access | Auth server, token endpoint |
| JWT | Token-based auth | Public key, issuer, claims |
| mTLS | Certificate auth | Trusted CAs, validation |
| Basic Auth | Username/password | Credential validation |
| IP Filtering | Network restrictions | Whitelist/blacklist IPs |

### Transformation Policies

| Policy | Use Case | Configuration |
|--------|----------|---------------|
| JSON to JSON | Transform structure | JOLT specification |
| JSON to XML | Format conversion | Root element |
| XML to JSON | Format conversion | Namespace handling |
| Transform Headers | Modify headers | Add/remove/update rules |
| URL Rewriting | Change paths | Regex patterns |

### Traffic Management Policies

| Policy | Use Case | Configuration |
|--------|----------|---------------|
| Rate Limit | Throttle requests | Limit, time unit, scope |
| Quota | Long-term limits | Limit, period (day/month) |
| Circuit Breaker | Fault tolerance | Failure threshold, timeout |
| Cache | Response caching | TTL, cache key, methods |
| Retry | Automatic retries | Max attempts, backoff |

### Validation Policies

| Policy | Use Case | Configuration |
|--------|----------|---------------|
| JSON Validation | Schema validation | JSON Schema |
| XML Validation | Schema validation | XSD schema |
| Request Validation | OpenAPI validation | OAS specification |

---

**End of User Guide**

---

## Document Information

**Document Title**: Gravitee API Management - User Guide
**Version**: 1.0
**Target Platform**: Gravitee APIM 4.x (Self-Hosted)
**Audience**: API Developers and Publishers
**Last Updated**: 2024

This documentation focuses on practical, workflow-based guidance for using Gravitee APIM in self-hosted environments. For installation instructions, infrastructure setup, and cloud-specific features, refer to the official Gravitee documentation.
