# Gravitee API Management - Architecture Documentation

> **Version:** 4.11.0-SNAPSHOT
> **Generated:** 2026-01-03
> **Repository:** https://github.com/gravitee-io/gravitee-api-management

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Overview](#system-overview)
3. [High-Level Architecture](#high-level-architecture)
4. [Core Components](#core-components)
5. [Module Organization](#module-organization)
6. [Gateway Architecture](#gateway-architecture)
7. [Management API Architecture](#management-api-architecture)
8. [Repository Layer](#repository-layer)
9. [Plugin System](#plugin-system)
10. [Frontend Architecture](#frontend-architecture)
11. [Data Flow & Communication](#data-flow--communication)
12. [Deployment Architecture](#deployment-architecture)
13. [Security Architecture](#security-architecture)
14. [Technology Stack](#technology-stack)

---

## Executive Summary

Gravitee API Management (APIM) is a comprehensive, open-source API management platform built on a microservices architecture. The platform provides complete API lifecycle management including design, deployment, security, monitoring, and analytics.

**Key Capabilities:**
- High-performance API Gateway with policy-based traffic management
- Comprehensive Management API for API lifecycle operations
- Pluggable architecture supporting multiple protocols (HTTP, WebSocket, gRPC, Kafka, MQTT, SSE)
- Multi-backend data persistence (MongoDB, PostgreSQL, MySQL, Elasticsearch, Redis)
- Rich UI for both administrators (Console) and developers (Portal)
- Extensible plugin system for custom policies, endpoints, and integrations

---

## System Overview

### Core Philosophy

Gravitee APIM is designed around three fundamental principles:

1. **Flexibility**: Pluggable backends, extensible policies, and protocol-agnostic design
2. **Performance**: Reactive architecture with Vert.x and RxJava for non-blocking I/O
3. **Scalability**: Distributed architecture with horizontal scaling capabilities

### Primary Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    GRAVITEE API MANAGEMENT                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │   Gateway      │  │ Management API │  │  Console UI    │   │
│  │   (Port 8082)  │  │  (Port 8083)   │  │  (Port 8084)   │   │
│  │                │  │                │  │                │   │
│  │  • Vert.x      │  │  • Spring Boot │  │  • Angular 19  │   │
│  │  • Reactive    │  │  • JAX-RS      │  │  • TypeScript  │   │
│  │  • Policies    │  │  • Services    │  │  • Material    │   │
│  └────────────────┘  └────────────────┘  └────────────────┘   │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Developer Portal UI (Port 4100)               │ │
│  │              • Angular 19 • OAuth2 OIDC                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Repository Layer                          │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │ │
│  │  │ MongoDB  │  │   JDBC   │  │   Redis  │  │Elastic-  │  │ │
│  │  │          │  │ (SQL DB) │  │          │  │search    │  │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## High-Level Architecture

### Logical Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CLIENT APPLICATIONS                            │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          API GATEWAY LAYER                               │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  Request Entry → Acceptor Resolution → Policy Chain Execution    │  │
│  │  → Backend Invocation → Response Processing → Client Response    │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  Components: Reactor, Handlers, Policies, Connectors, Security          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
        ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
        │   Backend    │  │  Analytics   │  │   Sync       │
        │   Services   │  │   Reporting  │  │   Service    │
        └──────────────┘  └──────────────┘  └──────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      MANAGEMENT API LAYER                                │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  REST Resources → Security Filters → Service Layer                │  │
│  │  → Repository Access → Event Publishing → Response               │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  Components: 295+ REST Resources, 133+ Services, Security, Events       │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       REPOSITORY LAYER                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │  Management │  │  Analytics  │  │ Rate Limit  │  │   Sync      │  │
│  │  (MongoDB/  │  │ (Elastic-   │  │  (Redis/    │  │  (Redis)    │  │
│  │   JDBC)     │  │  search)    │  │  Mongo)     │  │             │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        UI LAYER                                          │
│  ┌────────────────────────────────┐  ┌───────────────────────────────┐ │
│  │   Management Console           │  │   Developer Portal            │ │
│  │   • API Management             │  │   • API Discovery             │ │
│  │   • Policy Configuration       │  │   • Documentation             │ │
│  │   • Analytics & Monitoring     │  │   • Subscriptions             │ │
│  │   • User Management            │  │   • OAuth2 Authentication     │ │
│  └────────────────────────────────┘  └───────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. API Gateway

**Purpose:** High-performance request processor and policy engine

**Key Responsibilities:**
- Accept incoming API requests (HTTP, WebSocket, gRPC, TCP)
- Resolve API definitions and routes
- Execute policy chains for request/response transformation
- Invoke backend services
- Report analytics and metrics
- Health check monitoring

**Technology:**
- **Framework:** Vert.x 4.x (reactive, non-blocking)
- **Concurrency:** RxJava3 for reactive streams
- **Port:** 8082 (default)

**Architecture Pattern:** Chain of Responsibility with Reactive Streams

### 2. Management API

**Purpose:** RESTful API backend for API lifecycle management

**Key Responsibilities:**
- CRUD operations for APIs, Applications, Plans, Users
- API deployment and lifecycle management
- Authentication and authorization
- Event-driven synchronization with Gateway
- Audit logging and notifications
- Background job scheduling

**Technology:**
- **Framework:** Spring Boot 3.x
- **REST:** Jakarta JAX-RS with Jersey
- **Port:** 8083 (default)

**Architecture Pattern:** Layered architecture (Resources → Services → Repository)

### 3. Management Console UI

**Purpose:** Administrative web interface

**Key Features:**
- API design and policy configuration
- User and application management
- Analytics dashboards
- Audit trails and monitoring

**Technology:**
- **Framework:** Angular 19.2.4
- **Language:** TypeScript 5.5.4
- **UI Library:** Angular Material + Gravitee UI Components
- **Port:** 8084 (default)

### 4. Developer Portal UI

**Purpose:** API consumption interface for developers

**Key Features:**
- API catalog and discovery
- API documentation (Swagger, OpenAPI, Markdown)
- Application subscription management
- User account and notifications

**Technology:**
- **Framework:** Angular 19.2.5
- **Authentication:** OAuth2 OIDC
- **Documentation:** Swagger UI, ReDoc, Markdown
- **Port:** 4100 (default)

### 5. Repository Layer

**Purpose:** Abstract data persistence with multiple backend support

**Supported Backends:**
- **Management Data:** MongoDB (default) or JDBC (PostgreSQL, MySQL, SQL Server)
- **Analytics Data:** Elasticsearch (exclusive)
- **Rate Limiting:** Redis (preferred) or MongoDB/JDBC
- **Distributed Sync:** Redis (exclusive)

**Architecture Pattern:** Repository pattern with provider-based implementation selection

---

## Module Organization

### Maven Project Structure

The project is organized as a multi-module Maven monorepo with 15 major modules:

```
gravitee-api-management/
├── gravitee-apim-parent/              # Parent POM with shared configs
├── gravitee-apim-bom/                 # Bill of Materials (dependency versions)
├── gravitee-apim-common/              # Shared utilities
├── gravitee-apim-definition/          # API definition models
├── gravitee-apim-repository/          # Data persistence layer
│   ├── gravitee-apim-repository-api/
│   ├── gravitee-apim-repository-mongodb/
│   ├── gravitee-apim-repository-jdbc/
│   ├── gravitee-apim-repository-elasticsearch/
│   └── gravitee-apim-repository-redis/
├── gravitee-apim-rest-api/            # Management API backend
│   ├── gravitee-apim-rest-api-management/       # v1 REST resources
│   ├── gravitee-apim-rest-api-management-v2/    # v2 REST resources
│   ├── gravitee-apim-rest-api-service/          # Business logic
│   ├── gravitee-apim-rest-api-services/         # Background jobs
│   ├── gravitee-apim-rest-api-security/         # Auth & authz
│   └── gravitee-apim-rest-api-model/            # DTOs
├── gravitee-apim-gateway/             # API Gateway
│   ├── gravitee-apim-gateway-core/
│   ├── gravitee-apim-gateway-reactor/
│   ├── gravitee-apim-gateway-policy/
│   ├── gravitee-apim-gateway-handlers/
│   ├── gravitee-apim-gateway-services/
│   └── gravitee-apim-gateway-standalone/
├── gravitee-apim-plugin/              # Plugin infrastructure
│   ├── gravitee-apim-plugin-endpoint/
│   ├── gravitee-apim-plugin-entrypoint/
│   ├── gravitee-apim-plugin-apiservice/
│   └── gravitee-apim-plugin-reactor/
├── gravitee-apim-console-webui/       # Management Console (Angular)
├── gravitee-apim-portal-webui/        # Developer Portal (Angular)
├── gravitee-apim-distribution/        # Build artifacts
├── gravitee-apim-integration-tests/   # Integration tests
├── gravitee-apim-e2e/                 # End-to-end tests
├── gravitee-apim-perf/                # Performance tests (k6)
├── docker/                            # Docker Compose setups
└── helm/                              # Kubernetes Helm charts
```

**Maven Build Profiles:**
- `all-modules` - Build everything (default)
- `main-modules` - Core components only
- `gateway-modules` - Gateway only
- `rest-api-modules` - Management API only
- `plugin-modules` - Plugins only

---

## Gateway Architecture

### Request Processing Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    HTTP REQUEST ARRIVES                          │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Vert.x HTTP Server (Port 8082)                                 │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  DefaultHttpRequestDispatcher (Reactive)                        │
│  • Creates MutableExecutionContext                              │
│  • Wraps request/response in Vert.x adapters                   │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Platform Processor Chain                                       │
│  • MetricsProcessor - Initialize metrics collection            │
│  • TransactionPreProcessor - Set transaction/request IDs       │
│  • TraceContextProcessor - OpenTelemetry tracing setup         │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Request Processor Chain                                        │
│  • XForwardProcessor - X-Forwarded headers                     │
│  • Pre-request processors                                       │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Acceptor Resolution (HttpAcceptorResolver)                     │
│  • Match request path to API definition                        │
│  • Resolve which API handler to invoke                         │
└─────────────────────────────────────────────────────────────────┘
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
┌────────────────────────┐  ┌────────────────────────┐
│  SyncApiReactor        │  │ DefaultApiReactor      │
│  (V2/V3 APIs)          │  │ (V4 APIs)              │
│  • Synchronous         │  │ • Asynchronous         │
│  • Policy chains       │  │ • Message reactors     │
└────────────────────────┘  └────────────────────────┘
            │                           │
            └─────────────┬─────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Flow Resolution                                                 │
│  • Evaluate flow conditions (HTTP method, path, custom)        │
│  • Select best-match flow                                       │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Security Chain (if plan has security)                          │
│  • API Key validation                                           │
│  • OAuth2 token validation                                      │
│  • JWT validation                                               │
│  • Subscription context setup                                   │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Policy Chain Execution (REQUEST phase)                         │
│  • Transform request headers/body                               │
│  • Rate limiting                                                │
│  • Caching                                                      │
│  • Custom policies                                              │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Endpoint Invocation                                            │
│  • HTTP Proxy to backend                                        │
│  • gRPC, Kafka, Mock endpoints                                 │
│  • Connection pooling and timeout handling                     │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Policy Chain Execution (RESPONSE phase)                        │
│  • Transform response headers/body                              │
│  • Error handling                                               │
│  • Response templates                                           │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Response Processor Chain                                       │
│  • ResponseTimeProcessor - Measure latency                     │
│  • ReporterProcessor - Send analytics                          │
│  • AlertProcessor - Trigger alerts                             │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  HTTP Response to Client                                         │
└─────────────────────────────────────────────────────────────────┘
```

### Key Gateway Components

#### 1. Reactor System
- **DefaultHttpRequestDispatcher**: Reactive HTTP request routing
- **SyncApiReactor**: Handles V2/V3 API definitions (synchronous)
- **DefaultApiReactor**: Handles V4 API definitions (asynchronous, message-based)
- **ApiReactorHandler**: Bridges reactor to handler registry

#### 2. Policy Engine
- **PolicyChain**: RxJava3 Completable-based policy execution
- **PolicyChainFactory**: Creates policy chains from flow definitions
- **PolicyManager**: Instantiates and manages policy lifecycle
- **50+ pre-built policies** (transform, rate limit, cache, security, etc.)

#### 3. Processor Chains
- **Platform Processors**: Gateway-level processing (metrics, tracing, transactions)
- **Request Processors**: Pre-API processing (headers, timeouts)
- **Response Processors**: Post-API processing (analytics, alerts)

#### 4. Flow Resolution
- **FlowResolver**: Condition-based flow selection
- **BestMatchFlowResolver**: Selects most specific matching flow
- **Condition Filters**: HTTP method/path matching, custom expressions

#### 5. Security Chain
- **HttpSecurityChain**: Security policy execution
- **AuthenticationHandler**: API key, OAuth2, JWT validation
- **SubscriptionService**: Plan and subscription validation

#### 6. Services
- **SyncService**: Periodic synchronization of API definitions from Management API
- **HealthCheckService**: Endpoint health monitoring
- **HeartbeatService**: Gateway liveness reporting
- **ReporterService**: Analytics and metrics reporting

### Gateway Configuration

**Location:** `gravitee-apim-gateway/gravitee-apim-gateway-standalone/gravitee-apim-gateway-standalone-distribution/src/main/resources/config/gravitee.yml`

**Key Configurations:**
```yaml
http:
  port: 8082

services:
  sync:
    cron: "*/5 * * * * *"  # API sync interval

  metrics:
    enabled: true
    prometheus:
      enabled: true

reporters:
  elasticsearch:
    enabled: true
    endpoints:
      - http://localhost:9200
```

---

## Management API Architecture

### Layered Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    REST RESOURCE LAYER                           │
│  295+ JAX-RS Resource Classes                                   │
│  • ApisResource, ApiResource, ApplicationsResource, etc.       │
│  • @Path, @GET, @POST, @PUT, @DELETE annotations             │
│  • Request validation and DTO mapping                          │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                 SECURITY & FILTER LAYER                          │
│  • SecurityContextFilter - Spring Security integration         │
│  • PermissionsFilter - @Permission annotation evaluation       │
│  • GraviteeContextFilter - Thread-local context setup          │
│  • CorsFilter - CORS configuration                             │
│  • RecaptchaFilter - Bot protection                            │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE LAYER                                 │
│  133+ Service Implementations                                   │
│  • ApiService, ApplicationService, SubscriptionService         │
│  • Business logic and validation                               │
│  • @Transactional boundaries                                   │
│  • Event publishing                                             │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              EVENT PUBLISHING & NOTIFICATION                     │
│  • EventService - Publish domain events                        │
│  • EventListeners - React to events                            │
│  • NotificationService - Multi-channel notifications           │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                   REPOSITORY LAYER                               │
│  67 Repository Interfaces                                       │
│  • ApiRepository, ApplicationRepository, UserRepository        │
│  • CRUD operations and custom queries                          │
│  • Pagination and search criteria                              │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                  DATABASE LAYER                                  │
│  • MongoDB or JDBC (PostgreSQL, MySQL, SQL Server)             │
│  • Transaction management                                       │
│  • Data persistence                                             │
└─────────────────────────────────────────────────────────────────┘
```

### Background Services

**Scheduled Services:** (10 background jobs)

1. **ScheduledSyncService** - Synchronize API changes to Gateway (every 5 seconds)
2. **ScheduledAutoFetchService** - Fetch API specs from remote URLs
3. **DictionaryService** - Refresh dynamic properties
4. **ScheduledSubscriptionsService** - Process subscription state transitions
5. **ScheduledSubscriptionPreExpirationNotificationService** - Expiration warnings
6. **ScheduledAuditCleanerService** - Clean old audit records
7. **ScheduledEventsCleaningService** - Archive old events
8. **ScheduledSearchIndexerService** - Index APIs for search (Elasticsearch)
9. **V3UpgraderService** - Migrate API definitions to V3/V4
10. **DynamicPropertyScheduler** - Refresh dynamic properties

### Event System

**Event Flow:**
```
Service Layer Action (create/update/delete API)
    ↓
EventService.createApiEvent(API_DEPLOY)
    ↓
Event persisted in database
    ↓
EventListeners notified (async)
    ↓
├─ ApiEventListener → Deploy/undeploy API services
├─ NotificationTemplateCommandListener → Send notifications
└─ Other domain-specific listeners
```

**Event Types:** API_CREATE, API_UPDATE, API_DEPLOY, API_UNDEPLOY, PLAN_CREATE, SUBSCRIPTION_CREATE, USER_CREATE, etc.

---

## Repository Layer

### Multi-Backend Architecture

The repository layer uses a **provider pattern** to support multiple database backends:

```
┌─────────────────────────────────────────────────────────────────┐
│                  REPOSITORY PROVIDER PATTERN                     │
└─────────────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   MongoDB    │  │     JDBC     │  │ Elasticsearch│
│   Provider   │  │   Provider   │  │   Provider   │
│              │  │              │  │              │
│ Scopes:      │  │ Scopes:      │  │ Scopes:      │
│ • MANAGEMENT │  │ • MANAGEMENT │  │ • ANALYTICS  │
│ • RATE_LIMIT │  │ • RATE_LIMIT │  │              │
└──────────────┘  └──────────────┘  └──────────────┘

        ┌─────────────────┐
        │   Redis Provider │
        │                  │
        │ Scopes:          │
        │ • RATE_LIMIT     │
        │ • DISTRIBUTED_   │
        │   SYNC           │
        └──────────────────┘
```

### Scope-Based Data Distribution

| Data Type | Scope | Primary Backend | Alternative |
|-----------|-------|-----------------|-------------|
| API Definitions | MANAGEMENT | MongoDB | JDBC |
| Applications | MANAGEMENT | MongoDB | JDBC |
| Users & Roles | MANAGEMENT | MongoDB | JDBC |
| Organizations | MANAGEMENT | MongoDB | JDBC |
| Analytics Metrics | ANALYTICS | Elasticsearch | None |
| Request Logs | ANALYTICS | Elasticsearch | None |
| Health Checks | ANALYTICS | Elasticsearch | None |
| Rate Limits | RATE_LIMIT | Redis | MongoDB/JDBC |
| Gateway Sync | DISTRIBUTED_SYNC | Redis | None |

### Repository Interfaces

**Location:** `gravitee-apim-repository/gravitee-apim-repository-api/src/main/java/io/gravitee/repository/management/api/`

**67 Repository Interfaces:**
- `ApiRepository`, `ApplicationRepository`, `PlanRepository`, `SubscriptionRepository`
- `UserRepository`, `RoleRepository`, `GroupRepository`, `MembershipRepository`
- `AuditRepository`, `EventRepository`, `AlertTriggerRepository`
- `PageRepository`, `MetadataRepository`, `CategoryRepository`
- And 50+ more...

**Base Interface:**
```java
public interface CrudRepository<T, ID> extends FindAllRepository<T> {
    Optional<T> findById(ID id) throws TechnicalException;
    T create(T item) throws TechnicalException;
    T update(T item) throws TechnicalException;
    void delete(ID id) throws TechnicalException;
}
```

### Transaction Management

**JDBC Transactions:**
- Annotation-based: `@Transactional(value = "graviteeTransactionManager")`
- Spring `DataSourceTransactionManager`
- ACID guarantees for management data

**MongoDB Transactions:**
- Session-based transactions via `MongoTemplate`
- Atomic operations for CRUD

**Redis Operations:**
- Atomic increment-and-get for rate limiting
- No distributed transactions

---

## Plugin System

### Plugin Types

Gravitee APIM supports 6 plugin types:

1. **Endpoint Connectors** - Backend service connectors
   - HTTP Proxy, gRPC, Mock, Kafka, etc.
   - Interface: `EndpointConnectorPlugin<Factory, Config>`

2. **Entrypoint Connectors** - Request entry points
   - HTTP, WebSocket, SSE, Webhook
   - Interface: `EntrypointConnectorPlugin<Factory, Config>`

3. **API Service Plugins** - API-level services
   - Health checks, Dynamic properties, Service discovery
   - Interface: `ApiServicePlugin<Factory, Config>`

4. **Reactor Plugins** - Message reactors
   - Interface: `ReactorPlugin<Factory>`

5. **Policy Plugins** - Request/response policies
   - 50+ built-in policies (transform, rate limit, cache, security)

6. **Resource Plugins** - Shared resources
   - OAuth2 providers, caches, authentication

### Plugin Loading Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│  1. PLUGIN DISCOVERY                                            │
│  • Scan plugin directories                                      │
│  • Read plugin.properties manifest                              │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. PLUGIN HANDLER REGISTRATION                                 │
│  • PluginHandler.canHandle(plugin) - Type check               │
│  • Create isolated URLClassLoader                              │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. CONFIGURATION DISCOVERY                                     │
│  • Reflection-based configuration class discovery              │
│  • ConfigurationClassFinder.lookupFirst()                      │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. FACTORY INSTANTIATION                                       │
│  • Load factory class from plugin classloader                  │
│  • Inject PluginConfigurationHelper (optional)                │
│  • Store in PluginManager registry                             │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. RUNTIME USAGE                                               │
│  • PluginManager.getFactoryById(pluginId)                      │
│  • Factory creates connector/service instances                 │
│  • Configuration injected via JSON deserialization             │
└─────────────────────────────────────────────────────────────────┘
```

### Plugin Manifest Example

```properties
# plugin.properties
id=http-proxy-endpoint
name=HTTP Proxy Endpoint Connector
version=4.0.0
description=HTTP proxy endpoint for synchronous APIs
class=io.gravitee.plugin.endpoint.http.proxy.HttpProxyEndpointConnectorFactory
type=endpoint-connector
```

### Plugin Manager Architecture

**Manager Hierarchy:**
```
ConfigurablePluginManager<P extends Plugin>
  ├─ DefaultEndpointConnectorPluginManager
  ├─ DefaultEntrypointConnectorPluginManager
  ├─ DefaultApiServicePluginManager
  └─ DefaultReactorPluginManager
```

**Key Methods:**
- `register(Plugin plugin)` - Register plugin
- `getFactoryById(String id)` - Retrieve factory
- `getSchema(String id)` - Get JSON schema
- `getAllFactories()` - List all factories

---

## Frontend Architecture

### Management Console UI

**Technology Stack:**
- **Framework:** Angular 19.2.4
- **Language:** TypeScript 5.5.4
- **Components:** 542+ Angular components
- **UI Library:** Angular Material + Gravitee UI Components
- **State:** RxJS Observables (no Redux/NgRx)

**Module Organization:**
```
src/app/
├── auth/                  # Authentication
├── management/            # Core features (542 components)
│   ├── api/              # API management
│   ├── application/      # Application management
│   ├── analytics/        # Analytics dashboards
│   ├── settings/         # Global settings
│   └── ...
├── portal/               # Portal customization
├── organization/         # Organization settings
├── shared/               # Shared components (30+)
└── components/           # Feature components
```

**API Communication:**
- HTTP interceptors for auth, XSRF, error handling
- Angular services wrapping REST API calls
- Development proxy: `/management` → `http://localhost:8083`

**Routing:**
- Hash-based routing
- Lazy-loaded feature modules
- Route guards for authentication/authorization

### Developer Portal UI

**Technology Stack:**
- **Framework:** Angular 19.2.5
- **Authentication:** OAuth2 OIDC (`angular-oauth2-oidc`)
- **Components:** 58+ page components
- **Documentation:** Swagger UI, ReDoc, Markdown, AsciiDoc

**Module Organization:**
```
src/app/
├── pages/                # Page components
│   ├── catalog/         # API catalog
│   ├── api/             # API details
│   ├── user/            # User account
│   └── dashboard/       # User dashboard
├── components/          # Reusable components
├── services/            # Core services
└── resolvers/           # Route resolvers
```

**API Communication:**
- **Generated SDK:** `/projects/portal-webclient-sdk/`
- Auto-generated from OpenAPI spec
- Type-safe API clients

---

## Data Flow & Communication

### API Deployment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  MANAGEMENT CONSOLE - User deploys API                          │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  MANAGEMENT API - REST Resource Layer                           │
│  POST /apis/{apiId}/_deploy                                     │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  SERVICE LAYER - ApiService.deploy()                            │
│  • Validate API definition                                      │
│  • Update API state to STARTED                                  │
│  • Persist to repository                                        │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  EVENT PUBLISHING - EventService.createApiEvent(API_DEPLOY)     │
│  • Create event record in database                              │
│  • Set payload with API definition                              │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  GATEWAY - SyncService (every 5 seconds)                        │
│  • Poll for new events                                          │
│  • Fetch updated API definitions                                │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  GATEWAY - ApiManager.register(api)                             │
│  • Create ApiReactor handler                                    │
│  • Register acceptors (HTTP paths)                              │
│  • Initialize policy chains                                     │
│  • Make API ready to receive traffic                            │
└─────────────────────────────────────────────────────────────────┘
```

### Request Analytics Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  GATEWAY - API Request Processed                                │
│  • MetricsProcessor initializes metrics                         │
│  • ResponseTimeProcessor measures latency                       │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  GATEWAY - ReporterProcessor                                    │
│  • Create Reportable event                                      │
│  • ReporterService.report(event)                               │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  ELASTICSEARCH - Analytics Repository                           │
│  • Bulk indexing (batch 1000, flush 5s)                        │
│  • Daily indices or ILM policy                                  │
│  • Data types: request, monitor, health, log                   │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  MANAGEMENT CONSOLE - Analytics Dashboards                      │
│  • Query Elasticsearch via Management API                       │
│  • Visualize metrics with Highcharts                           │
│  • Display request logs and health data                         │
└─────────────────────────────────────────────────────────────────┘
```

### Inter-Module Communication Patterns

**Gateway ↔ Management API:**
- **Pattern:** Event-driven synchronization
- **Protocol:** REST API polling (Gateway pulls from Management API)
- **Frequency:** Every 5 seconds (configurable)
- **Data:** API definitions, dictionaries, plans, subscriptions

**Management API ↔ Database:**
- **Pattern:** Repository pattern with transactional boundaries
- **Protocol:** Native database protocol (MongoDB wire, JDBC, HTTP for ES)
- **Consistency:** ACID for MongoDB/JDBC, eventual for Elasticsearch

**Gateway ↔ Elasticsearch:**
- **Pattern:** Batch reporting
- **Protocol:** Elasticsearch HTTP API
- **Direction:** Gateway → Elasticsearch (write-only)
- **Data:** Analytics, logs, health checks, monitoring

**UI ↔ Management API:**
- **Pattern:** RESTful API client
- **Protocol:** HTTP/HTTPS with JSON
- **Authentication:** Session-based (Console), OAuth2 OIDC (Portal)
- **Security:** XSRF tokens, CORS configuration

---

## Deployment Architecture

### Standalone Deployment

```
┌──────────────────────────────────────────────────────────────┐
│                      Single Node                              │
│                                                               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │  Gateway   │  │ Management │  │  Console   │            │
│  │  :8082     │  │  API :8083 │  │  UI :8084  │            │
│  └────────────┘  └────────────┘  └────────────┘            │
│                                                               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │  MongoDB   │  │Elasticsearch│  │   Redis    │            │
│  │  :27017    │  │   :9200    │  │   :6379    │            │
│  └────────────┘  └────────────┘  └────────────┘            │
└──────────────────────────────────────────────────────────────┘
```

**Use Case:** Development, testing, small deployments

**Characteristics:**
- All components on single host
- Embedded databases or local Docker containers
- Quick setup via Docker Compose

### Distributed Deployment

```
┌──────────────────────────────────────────────────────────────┐
│                  Load Balancer / Reverse Proxy                │
└──────────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Gateway     │  │  Gateway     │  │  Gateway     │
│  Node 1      │  │  Node 2      │  │  Node N      │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          ▼
        ┌─────────────────────────────────────────┐
        │         Shared Databases                 │
        │  ┌──────────┐  ┌──────────┐  ┌────────┐│
        │  │ MongoDB  │  │Elasticsearch│ │ Redis ││
        │  │ Cluster  │  │   Cluster  │ │Cluster││
        │  └──────────┘  └──────────┘  └────────┘│
        └─────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│              Management API Cluster                           │
│  ┌──────────────┐  ┌──────────────┐                         │
│  │ Management   │  │ Management   │                         │
│  │ API Node 1   │  │ API Node 2   │                         │
│  └──────────────┘  └──────────────┘                         │
└──────────────────────────────────────────────────────────────┘
```

**Use Case:** Production, high-availability, high-performance

**Characteristics:**
- Multiple Gateway nodes for horizontal scaling
- Active-active Management API cluster
- Shared database clusters (MongoDB replica set, Elasticsearch cluster)
- Redis for distributed rate limiting and sync
- Load balancer distributes traffic

### Kubernetes Deployment

**Helm Chart:** `helm/`

**Components:**
- Gateway Deployment (StatefulSet or Deployment)
- Management API Deployment
- Console UI Deployment
- Portal UI Deployment
- Services for load balancing
- ConfigMaps for configuration
- Secrets for credentials
- PersistentVolumeClaims for storage

**Example:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gravitee-gateway
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: gateway
        image: graviteeio/apim-gateway:4.11.0
        ports:
        - containerPort: 8082
        env:
        - name: gravitee_management_mongodb_uri
          value: mongodb://mongo:27017/gravitee
```

---

## Security Architecture

### Authentication Mechanisms

**Management Console:**
- **Local Authentication:** Username/password stored in repository
- **LDAP/Active Directory:** External directory integration
- **OAuth2/OIDC:** Social login (Google, GitHub, Keycloak)
- **SAML 2.0:** Enterprise SSO

**Developer Portal:**
- **OAuth2 OIDC:** Primary authentication method
- **Social Providers:** Google, GitHub, custom OIDC providers
- **User Registration:** Self-service account creation
- **Password Reset:** Email-based password recovery

**Gateway API Security:**
- **API Key:** Simple key-based authentication
- **OAuth2:** Token validation (local or introspection)
- **JWT:** JSON Web Token validation
- **Keyless (Public):** No authentication required
- **Custom:** Plugin-based authentication

### Authorization Model

**RBAC (Role-Based Access Control):**

**Scopes:**
- **ORGANIZATION** - Organization-wide permissions
- **ENVIRONMENT** - Environment-specific permissions
- **API** - API-level permissions
- **APPLICATION** - Application-level permissions

**Roles:**
- Predefined: ADMIN, USER, API_PUBLISHER, etc.
- Custom: User-defined roles with specific permissions

**Permission Format:**
```
RolePermission.API_DEFINITION:CREATE_UPDATE_DELETE
RolePermission.APPLICATION:READ
```

**Annotation-Based Access Control:**
```java
@Permissions({
    @Permission(value = RolePermission.API_DEFINITION,
                acl = RolePermissionAction.UPDATE)
})
public Response updateApi(@PathParam("api") String apiId) { ... }
```

### Security Features

**CSRF Protection:**
- X-Xsrf-Token header validation
- Token stored in cookie
- Automatic token rotation

**CORS Configuration:**
- Per-environment CORS settings
- Configurable allowed origins, methods, headers
- Credentials support

**Rate Limiting:**
- Quota enforcement per plan/application
- Distributed rate limiting via Redis
- Spike arrest policies

**Input Validation:**
- Jakarta Bean Validation annotations
- Custom validators for domain logic
- JSON schema validation

**Audit Logging:**
- All administrative actions logged
- User, timestamp, action, before/after state
- Configurable retention period

---

## Technology Stack

### Backend Technologies

| Component | Technology | Version |
|-----------|-----------|---------|
| **Gateway Framework** | Vert.x | 4.x |
| **Reactive Streams** | RxJava | 3.x |
| **Management API** | Spring Boot | 3.x |
| **REST Framework** | Jersey (JAX-RS) | 3.x |
| **JSON Processing** | Jackson | 2.x |
| **Validation** | Jakarta Bean Validation | 3.x |
| **Build Tool** | Maven | 3.9+ |
| **Java Version** | Java | 17+ |

### Data Layer Technologies

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **MongoDB** | 5.0+ | Management data (default) |
| **PostgreSQL** | 12+ | Management data (alternative) |
| **MySQL** | 8.0+ | Management data (alternative) |
| **SQL Server** | 2019+ | Management data (alternative) |
| **Elasticsearch** | 7.x / 8.x | Analytics and search |
| **Redis** | 6.0+ | Rate limiting, distributed sync |

### Frontend Technologies

| Component | Technology | Version |
|-----------|-----------|---------|
| **Framework** | Angular | 19.2.x |
| **Language** | TypeScript | 5.5.x |
| **UI Library** | Angular Material | 19.2.x |
| **Design System** | Gravitee UI Components | 4.x |
| **Charts** | Highcharts | 9.x / 10.x |
| **Code Editor** | Monaco Editor | 0.46.x |
| **API Docs** | Swagger UI | 5.x |
| **Build Tool** | Angular CLI | 19.2.x |

### Testing Technologies

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Unit Tests** | JUnit 5 | Java unit testing |
| **Mocking** | Mockito | Test doubles |
| **Integration** | WireMock | HTTP mocking |
| **E2E Tests** | Cypress | UI end-to-end tests |
| **API Tests** | Jest | REST API testing |
| **Load Tests** | k6 | Performance testing |

### Deployment Technologies

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Containerization** | Docker | Container images |
| **Orchestration** | Kubernetes | Container orchestration |
| **Helm** | Helm 3 | Kubernetes package manager |
| **CI/CD** | GitHub Actions | Continuous integration |

---

## Conclusion

Gravitee API Management is a sophisticated, production-ready API management platform built on modern architectural principles:

**Strengths:**
- **Modularity:** Clean separation of concerns with 15 major modules
- **Flexibility:** Pluggable backends, extensible policies, protocol-agnostic
- **Performance:** Reactive architecture with non-blocking I/O
- **Scalability:** Horizontal scaling with distributed sync
- **Extensibility:** Comprehensive plugin system for customization

**Architecture Patterns:**
- Microservices architecture with event-driven synchronization
- Repository pattern with multiple backend support
- Chain of Responsibility for request processing
- Factory and Strategy patterns for plugin system
- Reactive programming with RxJava streams
- Layered architecture for Management API

This architecture enables Gravitee APIM to handle enterprise-scale API traffic while remaining flexible enough to adapt to diverse deployment scenarios and integration requirements.

---

**Document Version:** 1.0
**Last Updated:** 2026-01-03
**Author:** Generated from source code analysis
