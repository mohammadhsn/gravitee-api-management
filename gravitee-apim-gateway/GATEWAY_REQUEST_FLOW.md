# Gravitee API Gateway - Detailed HTTP Request Trace

This document provides a comprehensive trace of how an HTTP request flows through the Gravitee API Gateway, detailing each layer, package, class, and method involved in the process.

## Example Request
```
GET https://api.example.com/store/products/123
Host: api.example.com
Authorization: Bearer <token>
```

---

## PHASE 1: Bootstrap & HTTP Server Initialization

### 1.1 Gateway Bootstrap
```
Package: io.gravitee.gateway.standalone.vertx
Class:   VertxEmbeddedContainer
File:    gravitee-apim-gateway-standalone-container/.../VertxEmbeddedContainer.java
```

**What happens:**
- `doStart()` method initializes Vert.x HTTP server instances (default: CPU core count)
- Deploys `HttpProtocolVerticle` using Spring Verticle Factory
- Each verticle runs on its own event loop thread

```java
// Line 73-89
private void startHttpInstances() {
    final var options = new DeploymentOptions().setInstances(httpInstances);
    final String verticleName = SpringVerticleFactory.VERTICLE_PREFIX + ':' + HttpProtocolVerticle.class.getName();
    vertx.deployVerticle(verticleName, options, ...);
}
```

---

## PHASE 2: Request Reception (Entry Point)

### 2.1 HTTP Protocol Verticle
```
Package: io.gravitee.gateway.reactive.standalone.vertx
Class:   HttpProtocolVerticle
File:    gravitee-apim-gateway-standalone-container/.../HttpProtocolVerticle.java
```

**What happens:**
- Vert.x HTTP server receives the raw HTTP request
- `requestHandler` callback triggers `dispatchRequest()` method
- Connection timestamp recorded for metrics
- RxJava schedulers configured to use Vert.x event loop

```java
// Line 94 - Request handler registration
.requestHandler(request -> dispatchRequest(request, gioServer.id()))

// Line 122-129 - Dispatch method
private void dispatchRequest(HttpServerRequest request, String serverId) {
    requestDispatcher
        .dispatch(request, serverId)  // <-- Delegates to DefaultHttpRequestDispatcher
        .doOnComplete(() -> log.debug("Request properly dispatched"))
        .onErrorResumeNext(t -> handleError(t, request.response()))
        .subscribe();
}
```

---

## PHASE 3: Request Dispatching & Route Resolution

### 3.1 HTTP Request Dispatcher
```
Package: io.gravitee.gateway.reactive.reactor
Class:   DefaultHttpRequestDispatcher
File:    gravitee-apim-gateway-reactor/.../DefaultHttpRequestDispatcher.java
```

**What happens:**
- Central orchestrator for all incoming HTTP requests
- Resolves which API should handle the request
- Creates execution context with request/response wrappers
- Determines execution mode (V4 Emulation vs V3 Legacy)

```java
// Line 142-241 - Main dispatch method
public Completable dispatch(HttpServerRequest httpServerRequest, String serverId) {
    log.debug("Dispatching request on host {} and path {}", httpServerRequest.host(), httpServerRequest.path());

    // STEP 1: Resolve the handler (API) for this request
    final HttpAcceptor httpAcceptor = httpAcceptorResolver.resolve(
        httpServerRequest.host(),    // "api.example.com"
        httpServerRequest.path(),    // "/store/products/123"
        serverId
    );

    // STEP 2: Create execution context
    MutableExecutionContext mutableCtx = prepareExecutionContext(httpServerRequest);

    // STEP 3: Route to appropriate handler
    if (httpAcceptor == null) {
        return handleNotFound(mutableCtx);  // 404 flow
    } else if (httpAcceptor.reactor() instanceof ApiReactor<?> apiReactor) {
        // V4 Emulation Engine flow
        return apiReactor.handle(mutableCtx);
    } else {
        // V3 Legacy flow
        return handleV3Request(httpServerRequest, httpAcceptor);
    }
}
```

### 3.2 HTTP Acceptor Resolution
```
Package: io.gravitee.gateway.reactive.reactor.handler
Class:   DefaultHttpAcceptorResolver
File:    gravitee-apim-gateway-reactor/.../DefaultHttpAcceptorResolver.java
```

**What happens:**
- Iterates through registered API acceptors
- Matches request host + path against registered virtual hosts
- Returns the first matching `HttpAcceptor`

```java
// Line 34-42
public HttpAcceptor resolve(String host, String path, String serverId) {
    for (HttpAcceptor httpAcceptor : handlerRegistry.getAcceptors(HttpAcceptor.class)) {
        if (httpAcceptor.accept(host, path, serverId)) {
            return httpAcceptor;
        }
    }
    return null;
}
```

### 3.3 HTTP Acceptor Matching Logic
```
Package: io.gravitee.gateway.reactor.handler
Class:   AbstractHttpAcceptor
File:    gravitee-apim-gateway-reactor/.../AbstractHttpAcceptor.java
```

**What happens:**
- Matches server ID (if specified)
- Matches host (case-insensitive, null host matches any)
- Matches path prefix

```java
// Line 113-115 - Accept method
public boolean accept(String host, String path, String serverId) {
    return matchServer(serverId) && matchHost(host) && matchPath(path);
}

// Line 126-128 - Path matching
private boolean matchPath(String path) {
    return path.startsWith(this.path) || path.equals(pathWithoutTrailingSlash);
}
```

**Priority calculation:**
- Host-specific paths get +1000 priority bonus
- More specific paths (more `/` segments) have higher priority

---

## PHASE 4: API Reactor Handling

### 4.1 Sync API Reactor (V4 Emulation Engine)
```
Package: io.gravitee.gateway.reactive.handlers.api
Class:   SyncApiReactor
File:    gravitee-apim-gateway-handlers-api/.../SyncApiReactor.java
```

**What happens:**
- Main handler for V4 Emulation APIs
- Orchestrates the entire request/response lifecycle
- Manages processor chains, flow chains, security, and invoker

```java
// Line 205-217 - Entry point
public Completable handle(final MutableExecutionContext ctx) {
    ctx.componentProvider(componentProvider);
    ctx.templateVariableProviders(new HashSet<>(templateVariableProviders));

    prepareContextAttributes(ctx);  // Set API ID, context path, etc.
    prepareMetrics(ctx);            // Initialize metrics collection

    pendingRequests.incrementAndGet();
    return handleRequest(ctx).doFinally(pendingRequests::decrementAndGet);
}
```

### 4.2 Request Processing Pipeline
```java
// Line 246-275 - Full request processing chain
private Completable handleRequest(final MutableExecutionContext ctx) {
    return executeProcessorChain(ctx, beforeHandleProcessors, REQUEST)      // Logging init
        .andThen(organizationFlowChain.execute(ctx, REQUEST))               // Org-level flows
        .andThen(executeProcessorChain(ctx, beforeSecurityChainProcessors, REQUEST)) // CORS preflight
        .andThen(httpSecurityChain.execute(ctx))                            // AUTHENTICATION
        .andThen(executeProcessorChain(ctx, beforeApiFlowsProcessors, REQUEST))      // Path params, subscription
        .andThen(executeFlowChain(ctx, apiPlanFlowChain, REQUEST))          // Plan-level policies
        .andThen(executeFlowChain(ctx, apiFlowChain, REQUEST))              // API-level policies
        .andThen(invokeBackend(ctx))                                        // BACKEND CALL
        .andThen(executeFlowChain(ctx, apiPlanFlowChain, RESPONSE))         // Plan response policies
        .andThen(executeFlowChain(ctx, apiFlowChain, RESPONSE))             // API response policies
        .andThen(executeProcessorChain(ctx, afterApiFlowsProcessors, RESPONSE))
        .onErrorResumeNext(error -> processThrowable(ctx, error))           // Error handling
        .compose(upstream -> timeout(upstream, ctx))                        // Request timeout
        .andThen(executeFlowChain(ctx, organizationFlowChain, RESPONSE))    // Org response flows
        .onErrorResumeNext(t -> handleUnexpectedError(ctx, t))
        .andThen(executeProcessorChain(ctx, afterHandleProcessors, RESPONSE))
        .andThen(endResponse(ctx));                                         // Send response
}
```

---

## PHASE 5: Security Chain Execution

### 5.1 HTTP Security Chain
```
Package: io.gravitee.gateway.reactive.handlers.api.security
Class:   HttpSecurityChain
File:    gravitee-apim-gateway-handlers-api/.../security/HttpSecurityChain.java
```

**What happens:**
- Creates security plans from API plans (API Key, JWT, OAuth2, etc.)
- Executes plans in order until one successfully authenticates
- Sets subscription and application context on success

```java
// Line 55-68 - Constructor builds security plans from API definition
public HttpSecurityChain(Api api, PolicyManager policyManager, ExecutionPhase executionPhase) {
    super(
        Flowable.fromIterable(
            api.getPlans().stream()
                .map(plan -> HttpSecurityPlanFactory.forPlan(plan, policyManager))
                .filter(Objects::nonNull)
                .sorted(Comparator.comparingInt(HttpSecurityPlan::order))
                .collect(Collectors.toList())
        )
    );
}

// Line 81-88 - Execute each security plan
protected Single<Boolean> executePlan(HttpSecurityPlan httpSecurityPlan, HttpPlainExecutionContext ctx) {
    return HookHelper.hook(
        () -> httpSecurityPlan.execute(ctx, executionPhase),
        httpSecurityPlan.id(),
        securityPlanHooks, ctx, executionPhase
    ).andThen(TRUE);
}
```

---

## PHASE 6: Flow & Policy Chain Execution

### 6.1 Flow Chain
```
Package: io.gravitee.gateway.reactive.handlers.api.flow
Class:   FlowChain
File:    gravitee-apim-gateway-handlers-api/.../flow/FlowChain.java
```

**What happens:**
- Resolves flows matching the current request (path, method, condition)
- Executes policies in each flow sequentially
- Caches resolved flows for response phase reuse

```java
// Line 82-90 - Execute flow chain for a phase
public Completable execute(ExecutionContext ctx, ExecutionPhase phase) {
    return resolveFlows(ctx)
        .doOnNext(flow -> {
            log.debug("Executing flow {} ({} level, {} phase)", flow.getName(), id, phase.name());
            ctx.putInternalAttribute(ATTR_INTERNAL_FLOW_STAGE, id);
        })
        .concatMapCompletable(flow -> executeFlow(ctx, flow, phase))
        .doOnComplete(() -> ctx.removeInternalAttribute(ATTR_INTERNAL_FLOW_STAGE));
}

// Line 126-131 - Execute individual flow
private Completable executeFlow(ExecutionContext ctx, Flow flow, ExecutionPhase phase) {
    HttpPolicyChain policyChain = policyChainFactory.create(id, flow, phase);
    return HookHelper.hook(
        () -> policyChain.execute(ctx),
        policyChain.getId(), hooks, ctx, phase
    );
}
```

### 6.2 HTTP Policy Chain
```
Package: io.gravitee.gateway.reactive.policy
Class:   HttpPolicyChain
File:    gravitee-apim-gateway-policy/.../HttpPolicyChain.java
```

**What happens:**
- Executes policies in sequence for the given phase
- Calls `onRequest()` or `onResponse()` based on phase
- Supports hooks for tracing and logging

```java
// Line 108-124 - Execute individual policy
protected Completable executePolicy(BaseExecutionContext baseCtx, HttpPolicy policy) {
    log.debug("Executing policy {} on phase {} in policy chain {}", policy.id(), phase, id);

    HttpExecutionContext ctx = (HttpExecutionContext) baseCtx;
    return switch (phase) {
        case REQUEST -> HookHelper.hook(() -> policy.onRequest(ctx), policy.id(), policyHooks, ctx, phase);
        case RESPONSE -> HookHelper.hook(() -> policy.onResponse(ctx), policy.id(), policyHooks, ctx, phase);
        case MESSAGE_REQUEST -> HookHelper.hook(() -> policy.onMessageRequest(ctx), ...);
        case MESSAGE_RESPONSE -> HookHelper.hook(() -> policy.onMessageResponse(ctx), ...);
        default -> Completable.error(new IllegalArgumentException("Execution phase unknown"));
    };
}
```

---

## PHASE 7: Backend Invocation

### 7.1 Backend Invocation (in SyncApiReactor)
```java
// Line 315-332 - invokeBackend method
private Completable invokeBackend(final MutableExecutionContext ctx) {
    return defer(() -> {
        if (!Objects.equals(false, ctx.<Boolean>getInternalAttribute(ATTR_INTERNAL_INVOKER))) {
            HttpInvoker invoker = getInvoker(ctx);
            if (invoker != null) {
                return HookHelper.hook(
                    () -> invoker.invoke(ctx),
                    invoker.getId(), invokerHooks, ctx, null
                );
            }
        }
        return Completable.complete();
    })
    .doOnSubscribe(d -> ctx.metrics().setEndpointResponseTimeMs(System.currentTimeMillis()))
    .doOnTerminate(() -> setApiResponseTimeMetric(ctx));
}
```

### 7.2 HTTP Endpoint Invoker
```
Package: io.gravitee.gateway.reactive.core.v4.invoker
Class:   HttpEndpointInvoker
File:    gravitee-apim-gateway-core/.../v4/invoker/HttpEndpointInvoker.java
```

**What happens:**
- Resolves endpoint connector based on entrypoint requirements
- Handles dynamic endpoint targeting (via EL expressions)
- Connects to backend via endpoint connector

```java
// Line 72-94 - Main invoke method
public Completable invoke(final HttpExecutionContext ctx) {
    final HttpEndpointConnector endpointConnector = resolveConnector(ctx);

    if (endpointConnector == null) {
        return ctx.interruptWith(
            new ExecutionFailure(HttpStatusCode.SERVICE_UNAVAILABLE_503)
                .key(NO_ENDPOINT_FOUND_KEY)
        );
    }

    return connect(endpointConnector, ctx);
}

// Line 96-132 - Resolve endpoint connector
private <T extends HttpEndpointConnector> T resolveConnector(HttpExecutionContext ctx) {
    // Get entrypoint connector to determine supported API type and modes
    HttpEntrypointConnector entrypointConnector = ctx.getInternalAttribute(ATTR_INTERNAL_ENTRYPOINT_CONNECTOR);

    EndpointCriteria endpointCriteria = new EndpointCriteria(
        entrypointConnector.supportedApi(),
        entrypointConnector.supportedModes()
    );

    // Handle dynamic endpoint targeting
    String endpointTarget = ctx.getAttribute(ATTR_REQUEST_ENDPOINT);
    if (endpointTarget != null) {
        String evaluatedTarget = ctx.getTemplateEngine().getValue(endpointTarget, String.class);
        // Parse "endpoint-name:/path" format or absolute URLs
    }

    // Get next available endpoint from load balancer
    ManagedEndpoint managedEndpoint = endpointManager.next(endpointCriteria);
    return managedEndpoint.getConnector();
}
```

---

## PHASE 8: Processor Chain (Cross-cutting Concerns)

### 8.1 Processor Chain
```
Package: io.gravitee.gateway.reactive.core.processor
Class:   ProcessorChain
File:    gravitee-apim-gateway-core/.../processor/ProcessorChain.java
```

**What happens:**
- Executes processors sequentially (logging, CORS, headers, etc.)
- Used for pre/post API execution processing

```java
// Line 62-68 - Execute processor chain
public Completable execute(HttpExecutionContextInternal ctx, ExecutionPhase phase) {
    return processors.concatMapCompletable(processor -> executeNext(ctx, processor, phase));
}

private Completable executeNext(HttpExecutionContextInternal ctx, Processor processor, ExecutionPhase phase) {
    log.debug("Executing processor {} in processor chain {}", processor.getId(), id);
    return HookHelper.hook(() -> processor.execute(ctx), processor.getId(), processorHooks, ctx, phase);
}
```

---

## Complete Request Flow Diagram

```
+------------------------------------------------------------------------------+
|  CLIENT REQUEST: GET https://api.example.com/store/products/123              |
+------------------------------------------------------------------------------+
                                        |
                                        v
+------------------------------------------------------------------------------+
| LAYER 1: Vert.x HTTP Server                                                  |
| ---------------------------------------------------------------------------- |
| Package: io.gravitee.gateway.reactive.standalone.vertx                       |
| Class:   HttpProtocolVerticle                                                |
| Method:  dispatchRequest(HttpServerRequest, serverId)                        |
| Action:  Receives raw HTTP request, delegates to dispatcher                  |
+------------------------------------------------------------------------------+
                                        |
                                        v
+------------------------------------------------------------------------------+
| LAYER 2: Request Dispatcher                                                  |
| ---------------------------------------------------------------------------- |
| Package: io.gravitee.gateway.reactive.reactor                                |
| Class:   DefaultHttpRequestDispatcher                                        |
| Method:  dispatch(HttpServerRequest, serverId)                               |
| Action:  Resolves API handler, creates execution context                     |
| ---------------------------------------------------------------------------- |
| Package: io.gravitee.gateway.reactive.reactor.handler                        |
| Class:   DefaultHttpAcceptorResolver                                         |
| Method:  resolve(host, path, serverId)                                       |
| Action:  Matches request to registered API by host + path prefix             |
+------------------------------------------------------------------------------+
                                        |
                                        v
+------------------------------------------------------------------------------+
| LAYER 3: API Reactor (V4 Emulation Engine)                                   |
| ---------------------------------------------------------------------------- |
| Package: io.gravitee.gateway.reactive.handlers.api                           |
| Class:   SyncApiReactor                                                      |
| Method:  handle(MutableExecutionContext)                                     |
| Action:  Orchestrates full request lifecycle                                 |
+------------------------------------------------------------------------------+
                                        |
              +-------------------------+-------------------------+
              v                         v                         v
+-------------------------+ +-------------------------+ +-------------------------+
| LAYER 4a: Pre-Processors| | LAYER 4b: Org Flows     | | LAYER 4c: CORS Check    |
| ------------------------| | ------------------------| | ------------------------|
| ProcessorChain          | | FlowChain               | | ProcessorChain          |
| beforeHandleProcessors  | | organizationFlowChain   | | beforeSecurityChain     |
| - LogInitProcessor      | | - Org-level policies    | | - CorsPreflightProcessor|
| - LogRequestProcessor   | |                         | |                         |
+-------------------------+ +-------------------------+ +-------------------------+
                                        |
                                        v
+------------------------------------------------------------------------------+
| LAYER 5: Security Chain (Authentication)                                     |
| ---------------------------------------------------------------------------- |
| Package: io.gravitee.gateway.reactive.handlers.api.security                  |
| Class:   HttpSecurityChain                                                   |
| Method:  execute(ctx)                                                        |
| Action:  Authenticates request via API plans (API Key, JWT, OAuth2)          |
| Result:  Sets subscription, application, plan context attributes             |
+------------------------------------------------------------------------------+
                                        |
                                        v
+------------------------------------------------------------------------------+
| LAYER 6: Pre-API Execution Processors                                        |
| ---------------------------------------------------------------------------- |
| Package: io.gravitee.gateway.reactive.core.processor                         |
| Class:   ProcessorChain (beforeApiFlowsProcessors)                           |
| Action:  - XForwardedPrefixProcessor                                         |
|          - PathParametersProcessor (extracts {productId}=123)                |
|          - SubscriptionProcessor                                             |
|          - PathMappingProcessor                                              |
+------------------------------------------------------------------------------+
                                        |
                                        v
+------------------------------------------------------------------------------+
| LAYER 7: Policy Chains (REQUEST Phase)                                       |
| ---------------------------------------------------------------------------- |
| Package: io.gravitee.gateway.reactive.handlers.api.flow                      |
| Class:   FlowChain                                                           |
| ---------------------------------------------------------------------------- |
| Package: io.gravitee.gateway.reactive.policy                                 |
| Class:   HttpPolicyChain                                                     |
| Method:  execute(ctx) -> policy.onRequest(ctx)                               |
| ---------------------------------------------------------------------------- |
| Order:   1. apiPlanFlowChain  (Plan-level: rate-limit, quota)                |
|          2. apiFlowChain      (API-level: transform, validate, cache)        |
+------------------------------------------------------------------------------+
                                        |
                                        v
+------------------------------------------------------------------------------+
| LAYER 8: Backend Invocation                                                  |
| ---------------------------------------------------------------------------- |
| Package: io.gravitee.gateway.reactive.core.v4.invoker                        |
| Class:   HttpEndpointInvoker                                                 |
| Method:  invoke(ctx) -> resolveConnector() -> endpointConnector.connect()    |
| Action:  - Resolves endpoint via EndpointManager (load balancing)            |
|          - Connects to backend via HttpEndpointConnector                     |
|          - Streams request body, receives response                           |
+------------------------------------------------------------------------------+
                                        |
                                        v
+------------------------------------------------------------------------------+
| LAYER 9: Policy Chains (RESPONSE Phase)                                      |
| ---------------------------------------------------------------------------- |
| Class:   HttpPolicyChain                                                     |
| Method:  execute(ctx) -> policy.onResponse(ctx)                              |
| Order:   1. apiPlanFlowChain  (Plan response policies)                       |
|          2. apiFlowChain      (API response policies: transform response)    |
+------------------------------------------------------------------------------+
                                        |
                                        v
+------------------------------------------------------------------------------+
| LAYER 10: Post-Processing & Response                                         |
| ---------------------------------------------------------------------------- |
| Package: io.gravitee.gateway.reactive.core.processor                         |
| Class:   ProcessorChain (afterApiFlowsProcessors)                            |
| Action:  - ShutdownProcessor                                                 |
|          - TransactionPostProcessor                                          |
|          - CorsSimpleRequestProcessor                                        |
|          - FailureProcessor (if error)                                       |
| ---------------------------------------------------------------------------- |
| Method:  ctx.response().end(ctx) -> Writes response to client                |
+------------------------------------------------------------------------------+
                                        |
                                        v
+------------------------------------------------------------------------------+
|  RESPONSE: 200 OK (JSON payload)                                             |
+------------------------------------------------------------------------------+
```

---

## Key Classes Summary

| Layer | Package | Class | Responsibility |
|-------|---------|-------|----------------|
| 1 | `io.gravitee.gateway.standalone.vertx` | `VertxEmbeddedContainer` | Bootstrap Vert.x HTTP server |
| 2 | `io.gravitee.gateway.reactive.standalone.vertx` | `HttpProtocolVerticle` | HTTP request entry point |
| 3 | `io.gravitee.gateway.reactive.reactor` | `DefaultHttpRequestDispatcher` | Request routing orchestration |
| 4 | `io.gravitee.gateway.reactive.reactor.handler` | `DefaultHttpAcceptorResolver` | API route matching |
| 5 | `io.gravitee.gateway.reactor.handler` | `AbstractHttpAcceptor` | Host/path matching logic |
| 6 | `io.gravitee.gateway.reactive.handlers.api` | `SyncApiReactor` | API request lifecycle |
| 7 | `io.gravitee.gateway.reactive.handlers.api.security` | `HttpSecurityChain` | Authentication |
| 8 | `io.gravitee.gateway.reactive.handlers.api.flow` | `FlowChain` | Flow resolution & execution |
| 9 | `io.gravitee.gateway.reactive.policy` | `HttpPolicyChain` | Policy execution |
| 10 | `io.gravitee.gateway.reactive.core.processor` | `ProcessorChain` | Cross-cutting processors |
| 11 | `io.gravitee.gateway.reactive.core.v4.invoker` | `HttpEndpointInvoker` | Backend invocation |

---

## Plugin Integration Points

| Hook Point | Interface | Where Plugins Register |
|------------|-----------|------------------------|
| **Policies** | `HttpPolicy` | Via `PolicyManager`, loaded from plugin JARs |
| **Endpoint Connectors** | `HttpEndpointConnector` | Via `EndpointManager`, plugin registry |
| **Entrypoint Connectors** | `HttpEntrypointConnector` | Via entrypoint factory |
| **Resources** | `Resource` | Via `ResourceLifecycleManager` |
| **Reporters** | `Reporter` | Via reporter service |

---

## Module Structure

```
gravitee-apim-gateway/
├── gravitee-apim-gateway-standalone/
│   └── gravitee-apim-gateway-standalone-container/
│       └── VertxEmbeddedContainer.java      # Bootstrap
│       └── HttpProtocolVerticle.java        # Entry point
│
├── gravitee-apim-gateway-reactor/
│   └── DefaultHttpRequestDispatcher.java    # Request routing
│   └── DefaultHttpAcceptorResolver.java     # Route matching
│   └── AbstractHttpAcceptor.java            # Acceptor logic
│
├── gravitee-apim-gateway-handlers/
│   └── gravitee-apim-gateway-handlers-api/
│       └── SyncApiReactor.java              # API handling
│       └── HttpSecurityChain.java           # Security
│       └── FlowChain.java                   # Flow execution
│
├── gravitee-apim-gateway-policy/
│   └── HttpPolicyChain.java                 # Policy execution
│
└── gravitee-apim-gateway-core/
    └── ProcessorChain.java                  # Processors
    └── HttpEndpointInvoker.java             # Backend calls
```
