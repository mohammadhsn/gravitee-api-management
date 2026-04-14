# Gravitee API Management — Technical Guide (Self-Managed / Community Edition)

> This document covers the backend architecture, database structure, source code debugging, and core API endpoints of Gravitee APIM. It is intended for teams hosting Gravitee in a self-managed way and excludes enterprise-only features.

---

## Table of Contents

1. [System Architecture](#1-system-architecture)
2. [Database Structure](#2-database-structure)
3. [Debugging the Source Code](#3-debugging-the-source-code)
4. [Management API Endpoints](#4-management-api-endpoints)

---

## 1. System Architecture

### 1.1 Big Picture

Gravitee APIM is a monorepo built with **Apache Maven**. The platform consists of two main backend services — the **Management API** and the **Gateway** — that share a common data layer and plugin system.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Clients / Consumers                         │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     API Gateway (Vert.x)                           │
│   Accepts API traffic, enforces policies, routes to backends       │
│   Port: 8082                                                       │
└──────────┬──────────────────────────────────┬───────────────────────┘
           │ reads API definitions            │ writes analytics
           ▼                                  ▼
┌─────────────────────┐           ┌───────────────────────┐
│     MongoDB         │           │    Elasticsearch      │
│  (management data)  │           │  (analytics & logs)   │
└─────────┬───────────┘           └───────────────────────┘
          │ CRUD
          ▼
┌─────────────────────────────────────────────────────────────────────┐
│               Management API (Jetty / JAX-RS)                      │
│   Serves Console UI, Portal UI, and external integrations          │
│   Port: 8083                                                       │
└──────────┬──────────────────────────────────┬───────────────────────┘
           │                                  │
           ▼                                  ▼
┌─────────────────────┐           ┌───────────────────────┐
│    Console UI        │           │    Developer Portal   │
│    (Angular)         │           │    (Angular)          │
│    Port: 8084        │           │    Port: 8085         │
└─────────────────────┘           └───────────────────────┘
```

### 1.2 Backend Services

| Service | Technology | Port | Purpose |
|---------|-----------|------|---------|
| **Gateway** | Vert.x 4.x + RxJava 3 | 8082 | Receives API traffic, executes policy chains, proxies to backends, reports analytics |
| **Management API** | Spring Boot 3.x + Jetty + JAX-RS (Jersey) | 8083 | REST API for managing APIs, applications, users, and configuration. Serves both Console and Portal APIs |

### 1.3 Top-Level Modules

| Module | Purpose |
|--------|---------|
| `gravitee-apim-gateway` | API Gateway runtime — reactor, policy engine, connectors, HTTP/TCP handlers |
| `gravitee-apim-rest-api` | Management API — REST controllers, business logic, background services |
| `gravitee-apim-definition` | Shared API definition models (v2 and v4) and Jackson serialization |
| `gravitee-apim-repository` | Data access layer — interfaces + implementations for MongoDB, JDBC, Elasticsearch, Redis |
| `gravitee-apim-plugin` | Plugin system — endpoints, entrypoints, API services, reactor handlers |
| `gravitee-apim-common` | Shared utilities and MapStruct mappers |
| `gravitee-apim-distribution` | Packaging and assembly for distribution |

### 1.4 Gateway Architecture

The gateway is a reactive, non-blocking runtime built on Vert.x. Its main sub-modules:

| Sub-module | Role |
|-----------|------|
| `gateway-reactor` | Request dispatching — matches incoming requests to API handlers via acceptor resolvers |
| `gateway-core` | Execution context, connection management, failover, V4 support |
| `gateway-handlers` | API-level request handlers (`ApiReactorHandler`) and shared policy groups |
| `gateway-policy` | Policy execution engine — chains policies in request/response order |
| `gateway-flow` | Flow resolution — evaluates conditions to select which flows to execute |
| `gateway-http` / `gateway-tcp` | Protocol-specific handlers |
| `gateway-services` | Background services — sync, health checks, reporting, scheduling |
| `gateway-reporting` | Metrics and analytics reporting to Elasticsearch |
| `gateway-opentelemetry` | OpenTelemetry distributed tracing |

**Request processing flow:**

```
HTTP Request → Vert.x Server
  → DefaultHttpRequestDispatcher
    → Platform Processors (metrics, transaction IDs, tracing)
      → Acceptor Resolution (match path to API)
        → API Reactor (V2/V3: SyncApiReactor | V4: DefaultApiReactor)
          → Security Chain (API Key, OAuth2, JWT validation)
            → Request Policy Chain (transform, rate-limit, cache, etc.)
              → Endpoint Invocation (HTTP proxy, Mock, TCP proxy)
            → Response Policy Chain
          → Reporter Processor (analytics → Elasticsearch)
        → HTTP Response → Client
```

### 1.5 Management API Architecture

The management API follows a layered architecture:

| Layer | Modules | Role |
|-------|---------|------|
| **REST** | `rest-api-management` (v1), `rest-api-management-v2` (v2), `rest-api-portal` | JAX-RS resource classes — request parsing, response mapping |
| **Security** | `rest-api-security` | Filters for authentication (`SecurityContextFilter`) and authorization (`PermissionsFilter`) |
| **Service** | `rest-api-service` | Business logic, validation, event publishing |
| **Background Services** | `rest-api-services` | Scheduled jobs — audit, auto-fetch, dictionary sync, search indexing, subscription notifications, gateway sync |
| **Repository** | `rest-api-repository` → `gravitee-apim-repository` | Data access via repository interfaces |

**Request processing flow:**

```
REST Request → Jetty Server
  → SecurityContextFilter (JWT/token validation)
    → PermissionsFilter (@Permission annotation check)
      → JAX-RS Resource method
        → Service layer (business logic + @Transactional)
          → EventService (publishes domain events)
          → Repository layer (MongoDB/JDBC CRUD)
        → Response DTO → JSON
      → ExceptionMapper (if error)
    → HTTP Response
```

### 1.6 Inter-Service Communication

The Gateway and Management API communicate through **shared database + events**, not direct HTTP calls:

1. Management API persists API definitions to MongoDB and publishes an event (e.g., `API_DEPLOY`)
2. Gateway's **SyncService** polls the repository every 5 seconds (`*/5 * * * * *` cron)
3. Gateway loads updated API definitions into its in-memory store
4. New `ApiReactorHandler` instances are created/updated for changed APIs

For clustered gateways, **Redis** is used for distributed event synchronization and sync state coordination.

### 1.7 Plugin System

Gravitee is highly extensible through plugins. The `gravitee-apim-plugin` module provides:

| Plugin Type | Examples | Purpose |
|------------|---------|---------|
| **Endpoint** | `endpoint-http-proxy`, `endpoint-mock`, `endpoint-tcp-proxy` | Backend connection targets |
| **Entrypoint** | `entrypoint-http-proxy`, `entrypoint-tcp-proxy` | Client-facing API entry protocols |
| **API Service** | `apiservice-dynamicproperties`, `apiservice-healthcheck-http`, `apiservice-servicediscovery-consul` | Background services attached to APIs |
| **Reactor** | Message-driven reactor plugins | Custom reactor implementations |

Plugins are loaded from `$GRAVITEE_HOME/plugins` and `$GRAVITEE_HOME/plugins-ext` directories at startup.

---

## 2. Database Structure

### 2.1 Overview

Gravitee uses three storage backends:

| Backend | Purpose | Required |
|---------|---------|----------|
| **MongoDB** (or JDBC) | All management data — APIs, applications, users, plans, subscriptions, configuration | Yes |
| **Elasticsearch** | Analytics, request logs, health checks, V4 metrics | Yes |
| **Redis** | Rate limiting, distributed event sync, cluster state | Optional (needed for multi-node gateway) |

### 2.2 MongoDB Collections (Logical Overview)

Collection names use a configurable prefix (default: none). Grouped by domain:

#### Core API Management

| Collection | Purpose | Key Relationships |
|-----------|---------|-------------------|
| `apis` | API definitions — version, configuration, lifecycle state, visibility | Contains plans references |
| `plans` | API plans — security type, quotas, rate limits, validation mode | Belongs to an API |
| `subscriptions` | Application-to-API subscriptions through a plan | Links application → plan → API |
| `keys` | API keys issued for subscriptions | Belongs to a subscription |
| `flows` | Request/response policy flow definitions | Attached to APIs or platform |

#### Applications

| Collection | Purpose |
|-----------|---------|
| `applications` | Consumer applications that subscribe to APIs |

#### Users, Groups & Access

| Collection | Purpose |
|-----------|---------|
| `users` | User accounts (encrypted email/password) |
| `roles` | Role definitions with permission sets |
| `groups` | User groups |
| `memberships` | User-to-group membership assignments |
| `identity_providers` | External IdP configurations (OIDC, LDAP) |
| `identity_provider_activations` | IdP activation per environment |
| `tokens` | Personal access tokens |
| `invitations` | User invitations |
| `custom_user_fields` | Custom user profile fields |

#### Organization & Environment

| Collection | Purpose |
|-----------|---------|
| `organizations` | Top-level organization hierarchy |
| `environments` | Environment configurations within organizations |
| `access_points` | Access point configurations |
| `tenants` | Multi-tenancy support |
| `entrypoints` | Gateway entrypoint definitions |
| `parameters` | System/global parameters and settings |
| `installation` | Installation metadata |

#### Content & Documentation

| Collection | Purpose |
|-----------|---------|
| `pages` | Documentation/content pages |
| `page_revisions` | Page version history |
| `categories` | API categories/tags |
| `tags` | Sharding tags |
| `metadata` / `metadatas` | Metadata definitions and values |
| `themes` | Portal theme customizations |
| `dashboards` | Custom analytics dashboards |
| `dictionaries` | Dynamic property dictionaries |

#### Portal

| Collection | Purpose |
|-----------|---------|
| `portal_pages` | Portal-specific pages |
| `portal_page_contexts` | Portal page context configurations |
| `portal_page_contents` | Portal page content storage |
| `portal_navigation_items` | Portal navigation structure |
| `portal_menu_links` | Portal menu link configurations |

#### Notifications & Alerts

| Collection | Purpose |
|-----------|---------|
| `alert_triggers` | Alert trigger definitions |
| `alert_events` | Alert event instances |
| `portalnotifications` | Portal notification instances |
| `portalnotificationconfigs` | Portal notification preferences |
| `genericnotificationconfigs` | Generic notification configurations |
| `notificationTemplates` | Email/message templates |

#### Events, Audit & Jobs

| Collection | Purpose |
|-----------|---------|
| `events` | System events (API deploy, start, stop, etc.) |
| `events_latest` | Latest event per entity (optimization) |
| `audits` | Full audit trail of changes |
| `commands` | Async command queue |
| `asyncjobs` | Asynchronous job tracking |

#### Policies & Quality

| Collection | Purpose |
|-----------|---------|
| `sharedpolicygroups` | Reusable policy group definitions |
| `sharedpolicygrouphistories` | Policy group version history |
| `qualityrules` | Quality rule definitions |
| `apiqualityrules` | Quality rules applied to specific APIs |

#### Other

| Collection | Purpose |
|-----------|---------|
| `ratings` / `ratingAnswers` | API ratings and reviews |
| `tickets` | Support tickets |
| `workflows` | API review workflow state |
| `promotions` | API promotion between environments |
| `integrations` | Third-party integration configs |
| `client_registration_providers` | OIDC dynamic client registration |
| `licenses` | License information |
| `node_monitoring` | Gateway node monitoring data |
| `upgrades` | Database migration tracking |

### 2.3 Key Entity Relationships

```
Organization
  └── Environment
        ├── API
        │     ├── Plan (1:N)
        │     ├── Flow (1:N)
        │     ├── Page (documentation, 1:N)
        │     └── Metadata (1:N)
        │
        ├── Application
        │     └── Subscription → Plan → API
        │           └── API Key (1:N)
        │
        ├── User
        │     ├── Membership → Group
        │     └── Role (via membership)
        │
        └── Configuration
              ├── Category, Tag, Dictionary
              ├── Identity Provider
              ├── Notification Templates
              └── Portal Theme
```

### 2.4 Elasticsearch Indexes

Elasticsearch stores time-series analytics data. Index names follow the pattern `{prefix}-{type}-{date}` (default prefix: `gravitee`).

| Index Type | Content |
|-----------|---------|
| `gravitee-request-*` | V2/V3 API request logs — latency, status, consumer, API |
| `gravitee-health-check-*` | Health check probe results and endpoint availability |
| `gravitee-monitor-*` | Gateway node monitoring data |
| `gravitee-metrics-*` | V4 API metrics — connections, message counts |
| `gravitee-log-*` | Detailed request/response logs |
| `gravitee-message-log-*` | V4 message/event logs |
| `gravitee-message-metrics-*` | V4 message-level metrics |

Supports multiple index naming strategies: ILM-based (daily/weekly rollover), per-type, and multi-type.

### 2.5 Redis Data

Used when running multiple gateway nodes:

| Key Pattern | Purpose |
|------------|---------|
| `ratelimit:{subscriptionId}` | Rate limit counters per subscription — counter, limit, reset time |
| `distributed_event:{refType}:{refId}:{timestamp}` | Distributed event synchronization across gateway nodes |
| `distributed_sync_state:{clusterId}` | Cluster sync state hash |

---

## 3. Debugging the Source Code

### 3.1 Build System

The project uses **Maven 4.0.0** with build profiles to compile specific parts:

| Profile | Modules Built |
|---------|--------------|
| `all-modules` (default) | Everything |
| `main-modules` | Management API, Gateway, Definition, Common |
| `gateway-modules` | Gateway only |
| `rest-api-modules` | Management API only |
| `definition-modules` | API definition models only |
| `plugin-modules` | Plugin infrastructure |

Build from root:

```bash
mvn clean install -DskipTests              # full build
mvn clean install -P rest-api-modules -DskipTests  # management API only
mvn clean install -P gateway-modules -DskipTests   # gateway only
```

### 3.2 Management API Entry Point

**Bootstrap chain:**

```
Bootstrap.main()
  → GraviteeApisContainer (extends SpringBasedContainer)
    → StandaloneConfiguration (Spring @Configuration)
      → GraviteeManagementApplication (JAX-RS ResourceConfig)
        → Registers: OrganizationsResource, SecurityContextFilter, PermissionsFilter, ExceptionMappers
```

**Key files:**

| File | Purpose |
|------|---------|
| `rest-api-standalone-bootstrap/.../Bootstrap.java` | Main entry point. Sets `gravitee.home`, creates classloaders, starts container |
| `rest-api-standalone-container/.../GraviteeApisContainer.java` | Spring Boot container bootstrap |
| `rest-api-management-rest/.../GraviteeManagementApplication.java` | JAX-RS ResourceConfig — registers all REST resources, filters, exception mappers |
| `rest-api-standalone-distribution/.../config/gravitee.yml` | Main configuration file |

**To debug in an IDE**: Run `Bootstrap.main()` with VM argument `-Dgravitee.home=/path/to/distribution`.

### 3.3 Gateway Entry Point

**Bootstrap chain:**

```
Bootstrap.main()
  → GatewayContainer (extends SpringBasedContainer)
    → StandaloneConfiguration (Spring @Configuration)
      → Vert.x HTTP Server (port 8082)
        → DefaultHttpRequestDispatcher
```

**Key files:**

| File | Purpose |
|------|---------|
| `gateway-standalone-bootstrap/.../Bootstrap.java` | Main entry point |
| `gateway-standalone-container/.../GatewayContainer.java` | Spring Boot container. Also has a `main()` method for IDE debugging |
| `gateway-standalone-distribution/.../config/gravitee.yml` | Gateway configuration |

**To debug in an IDE**: Run `GatewayContainer.main()` with `-Dgravitee.home=/path/to/distribution`.

### 3.4 Module Dependency Graph

Understanding which module to look at for a given issue:

```
REST Layer (what you see as endpoints)
├── rest-api-management         ← v1 controllers under /management
├── rest-api-management-v2      ← v2 controllers under /v2
└── rest-api-portal             ← portal controllers under /portal
        │
        ▼
Service Layer (business logic)
├── rest-api-service            ← CRUD services, domain logic, converters
├── rest-api-services           ← background jobs (sync, audit, indexing, etc.)
└── rest-api-security           ← auth filters, permission checks
        │
        ▼
Data Layer (persistence)
├── rest-api-repository         ← repository abstraction
└── gravitee-apim-repository    ← implementations:
    ├── repository-mongodb      ←   MongoDB
    ├── repository-jdbc         ←   PostgreSQL, MySQL, SQL Server
    ├── repository-elasticsearch ←  analytics queries
    └── repository-redis        ←   rate limiting, distributed sync
```

### 3.5 Key Debugging Breakpoints

| What you're debugging | Where to set breakpoint |
|-----------------------|------------------------|
| Any Management API request | `SecurityContextFilter` — traces the auth chain |
| Permission/authorization issues | `PermissionsFilter` — checks `@Permission` annotations |
| API CRUD operations | `ApiService` (or `ApiCrudServiceImpl`) in `rest-api-service` |
| Gateway request processing | `ApiReactorHandler.doHandle()` — entry to API-level handling |
| Policy execution | `PolicyChain` execute/apply methods |
| Flow selection | `BestMatchFlowResolver` — evaluates conditions to select flows |
| Gateway sync from management | `SyncService` in `gateway-services` — polls for API definition changes |
| Startup/bootstrap | `Bootstrap.main()` or `GraviteeApisContainer.main()` / `GatewayContainer.main()` |

### 3.6 Service Naming Conventions

The service layer uses a consistent naming pattern:

| Pattern | Purpose | Example |
|---------|---------|---------|
| `*CrudService` | CRUD operations on a single entity | `ApiCrudService` |
| `*QueryService` | Read-only queries, search, filtering | `ApiQueryService` |
| `*DomainService` | Cross-aggregate business logic | `ApiDomainService` |

### 3.7 V2 vs V4 API Processing

The gateway has two parallel processing paths:

| Version | Reactor | Style |
|---------|---------|-------|
| V2/V3 APIs | `SyncApiReactor` | Synchronous proxy — request/response |
| V4 APIs | `DefaultApiReactor` | Reactive — supports event-driven, message-based patterns |

Spring qualifiers differentiate them:
- `@Qualifier("v3AcceptorResolver")` / `@Qualifier("v4AcceptorResolver")`
- `@Qualifier("v3RequestProcessorChainFactory")` / `@Qualifier("v4RequestProcessorChainFactory")`

### 3.8 Test Infrastructure

| Test Type | Location | Framework |
|-----------|----------|-----------|
| Unit tests | `src/test/java` in each module | JUnit 5 + Mockito |
| Integration tests | `gravitee-apim-integration-tests` | `@GatewayTest` annotation + Wiremock + Awaitility |
| E2E tests | `gravitee-apim-e2e` | End-to-end scenarios |
| Performance tests | `gravitee-apim-perf` | Load testing |

Gateway integration tests use `@GatewayTest(v2ExecutionMode = ExecutionMode.V3)` to specify API version mode.

---

## 4. Management API Endpoints

The Management API exposes three sets of REST endpoints:

| API | Base Path | Purpose | Consumers |
|-----|-----------|---------|-----------|
| **Management v1** | `/management/organizations/{orgId}/environments/{envId}/...` | Full API lifecycle management | Console UI, scripts |
| **Management v2** | `/management/v2/...` | Modern RESTful API management | Console UI, automation |
| **Portal** | `/portal/environments/{envId}/...` | User-facing API discovery and subscription | Developer Portal UI |

### 4.1 Management API v1 — Organization Level

**Base**: `/organizations/{orgId}`

| Category | Endpoint Pattern | Methods | Description |
|----------|-----------------|---------|-------------|
| **Organizations** | `/organizations` | GET, POST | List and create organizations |
| **Organization** | `/organizations/{orgId}` | GET, PUT | Get/update specific organization |
| **Environments** | `/{orgId}/environments` | GET, POST | List and create environments |
| **Users** | `/{orgId}/users` | GET, POST | User management |
| **Current User** | `/{orgId}/user` | GET, PUT | Current user profile, avatar, tasks, notifications, tokens |
| **Configuration** | `/{orgId}/configuration` | GET | Platform configuration |
| **Roles** | `/{orgId}/configuration/rolescopes` | GET | Role scope definitions |
| **Identity Providers** | `/{orgId}/configuration/identities` | GET, POST | IdP management |
| **Notification Templates** | `/{orgId}/configuration/notification-templates` | GET, PUT | Email/message templates |

### 4.2 Management API v1 — Environment Level

**Base**: `/organizations/{orgId}/environments/{envId}`

#### API Management

| Endpoint Pattern | Methods | Description |
|-----------------|---------|-------------|
| `/apis` | GET, POST | List, create, import APIs |
| `/apis/{apiId}` | GET, PUT, DELETE | CRUD on a specific API |
| `/apis/{apiId}/deploy` | POST | Deploy API to gateway |
| `/apis/{apiId}/state` | GET, POST | API lifecycle (start/stop) |
| `/apis/{apiId}/plans` | GET, POST | Plan management |
| `/apis/{apiId}/plans/{planId}` | GET, PUT, DELETE | Specific plan CRUD |
| `/apis/{apiId}/subscriptions` | GET, POST | Subscription management |
| `/apis/{apiId}/members` | GET, POST, DELETE | API team members |
| `/apis/{apiId}/metadata` | GET, POST | API metadata |
| `/apis/{apiId}/pages` | GET, POST | API documentation pages |
| `/apis/{apiId}/media` | GET, POST | API media files |
| `/apis/{apiId}/groups` | GET | API group associations |
| `/apis/{apiId}/quality-rules` | GET | API quality assessment |
| `/apis/{apiId}/ratings` | GET, POST | API ratings |

#### API Analytics & Monitoring

| Endpoint Pattern | Methods | Description |
|-----------------|---------|-------------|
| `/apis/{apiId}/analytics` | GET | API analytics (request counts, latency, etc.) |
| `/apis/{apiId}/logs` | GET | API request logs |
| `/apis/{apiId}/health` | GET | API health check results |
| `/apis/{apiId}/events` | GET | API lifecycle events |
| `/apis/{apiId}/audits` | GET | API audit trail |
| `/apis/{apiId}/alerts` | GET, POST | API alert rules |

#### Application Management

| Endpoint Pattern | Methods | Description |
|-----------------|---------|-------------|
| `/applications` | GET, POST | List and create applications |
| `/applications/{appId}` | GET, PUT, DELETE | Application CRUD |
| `/applications/{appId}/keys` | GET, POST | API key management |
| `/applications/{appId}/members` | GET, POST | Application team |
| `/applications/{appId}/metadata` | GET, POST | Application metadata |
| `/applications/{appId}/logs` | GET | Application request logs |
| `/applications/{appId}/analytics` | GET | Application analytics |
| `/applications/{appId}/alerts` | GET, POST | Application alert rules |

#### Platform & Configuration

| Endpoint Pattern | Methods | Description |
|-----------------|---------|-------------|
| `/configuration` | GET | Environment settings |
| `/categories` | GET, POST | API categories |
| `/groups` | GET, POST | User groups |
| `/tags` | GET, POST | Sharding tags |
| `/metadata` | GET, POST | Environment metadata |
| `/flows` | GET, PUT | Platform-level flows |
| `/policies` | GET | Available policies |
| `/resources` | GET | Available resources |
| `/connectors` | GET | Available connectors |
| `/fetchers` | GET | Available fetchers |
| `/entrypoints` | GET | Entrypoint definitions |
| `/analytics` | GET | Environment-level analytics |
| `/dashboards` | GET, POST | Custom dashboards |
| `/notifiers` | GET | Notification providers |

#### Portal Management

| Endpoint Pattern | Methods | Description |
|-----------------|---------|-------------|
| `/portal/pages` | GET, POST | Portal documentation pages |
| `/portal/settings` | GET, PUT | Portal settings |
| `/portal/media` | GET, POST | Portal media |

### 4.3 Management API v2

**Base**: `/v2` (flat RESTful structure)

| Category | Endpoint Pattern | Description |
|----------|-----------------|-------------|
| **APIs** | `/apis` | API CRUD, import, export, deploy, start, stop, duplicate, migrate |
| **API Plans** | `/apis/{apiId}/plans` | Plan management |
| **API Subscriptions** | `/apis/{apiId}/subscriptions` | Subscription management with export, verify |
| **API Members** | `/apis/{apiId}/members` | Team management, primary owner |
| **API Analytics** | `/apis/{apiId}/analytics` | Request counts, response time, status ranges |
| **API Health** | `/apis/{apiId}/health` | Average response time, availability, logs |
| **API Logs** | `/apis/{apiId}/logs` | Request logs with details |
| **API Audits** | `/apis/{apiId}/audits` | Audit trail |
| **API Events** | `/apis/{apiId}/events` | Lifecycle events |
| **API Scoring** | `/apis/{apiId}/scoring` | API quality scoring |
| **Applications** | `/applications` | Application CRUD |
| **Categories** | `/categories` | Category management with API associations |
| **Groups** | `/groups` | User group management |
| **Integrations** | `/integrations` | Third-party integrations |
| **Shared Policy Groups** | `/environments/{envId}/shared-policy-groups` | Reusable policy groups |
| **Async Jobs** | `/environments/{envId}/async-jobs` | Background job tracking |
| **Plugins** | `/plugins/entrypoints`, `/plugins/endpoints`, `/plugins/policies`, `/plugins/resources`, `/plugins/api-services` | Plugin discovery |
| **UI** | `/ui`, `/ui/themes`, `/ui/portal-menu-links` | UI configuration |
| **License** | `/license` | License information |

### 4.4 Portal API

**Base**: `/portal/environments/{envId}`

These endpoints serve the Developer Portal UI and are user-facing.

| Category | Endpoint Pattern | Description |
|----------|-----------------|-------------|
| **Bootstrap** | `/ui/bootstrap` | Portal initialization data |
| **APIs** | `/apis` | Browse and search published APIs |
| **API Detail** | `/apis/{apiId}` | API info, picture, background, metrics, pages, plans, ratings, media |
| **API Ratings** | `/apis/{apiId}/ratings` | Submit and read API reviews |
| **Categories** | `/categories` | Browse API categories |
| **Applications** | `/applications` | User's application management |
| **Application Detail** | `/applications/{appId}` | App config, members, metadata, keys, logs, analytics |
| **Subscriptions** | `/subscriptions` | User's subscriptions with key management |
| **Auth** | `/auth` | Login, logout, OAuth2 exchange |
| **User** | `/user` | Current user profile and notifications |
| **Registration** | `/users` | New user registration |
| **Configuration** | `/configuration` | Portal configuration |
| **Pages** | `/pages` | Portal documentation pages |
| **Tickets** | `/tickets` | Support ticket submission |
| **Theme** | `/theme` | Portal theme data |
| **Groups** | `/groups` | Available user groups |
| **Permissions** | `/permissions` | Current user permissions |

### 4.5 Source File Locations

| API | Source Path |
|-----|-----------|
| Management v1 | `gravitee-apim-rest-api/gravitee-apim-rest-api-management/gravitee-apim-rest-api-management-rest/src/main/java/io/gravitee/rest/api/management/rest/resource/` |
| Management v2 | `gravitee-apim-rest-api/gravitee-apim-rest-api-management-v2/gravitee-apim-rest-api-management-v2-rest/src/main/java/io/gravitee/rest/api/management/v2/rest/resource/` |
| Portal | `gravitee-apim-rest-api/gravitee-apim-rest-api-portal/gravitee-apim-rest-api-portal-rest/src/main/java/io/gravitee/rest/api/portal/rest/resource/` |

---

*This document was generated from the Gravitee APIM source code (version 4.11.x). For the latest information, refer to the source code and the official Gravitee documentation.*
