# Gravitee APIM - Local Setup Guide

> **Complete guide for running Gravitee API Management locally using Docker**
>
> **Last Updated:** 2026-01-03
> **Repository:** https://github.com/gravitee-io/gravitee-api-management

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start (5 Minutes)](#quick-start-5-minutes)
3. [Available Setup Options](#available-setup-options)
4. [Detailed Setup Instructions](#detailed-setup-instructions)
5. [Custom Configurations](#custom-configurations)
6. [Access Information](#access-information)
7. [Useful Commands](#useful-commands)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Topics](#advanced-topics)

---

## Prerequisites

### Required Software

- **Docker Desktop** (or Docker Engine + Docker Compose)
  - Version: 20.10+
  - Docker Compose: v2.0+
- **Minimum System Requirements:**
  - RAM: 4GB (8GB recommended)
  - Disk Space: 10GB free
  - CPU: 2 cores (4 cores recommended)

### Verify Installation

```bash
# Check Docker version
docker --version
# Should output: Docker version 20.10.x or higher

# Check Docker Compose version
docker-compose --version
# Should output: Docker Compose version v2.x.x or higher

# Verify Docker is running
docker info
```

### Increase Docker Resources (if needed)

1. Open Docker Desktop
2. Go to Settings → Resources
3. Set Memory to at least 4GB (8GB recommended)
4. Set CPUs to at least 2 (4 recommended)
5. Click "Apply & Restart"

---

## Quick Start (5 Minutes)

### Option 1: Using Makefile (Recommended)

```bash
# 1. Navigate to docker directory
cd docker

# 2. View available setups
make help

# 3. Start MongoDB setup (default, simplest)
make mongodb

# 4. Wait for services to start (30-60 seconds)
# Watch the logs to see when everything is ready
docker-compose -f quick-setup/mongodb/docker-compose.yml logs -f

# 5. Press Ctrl+C to exit logs when you see "Started successfully"

# 6. Access the Management Console
# Open browser: http://localhost:8084
# Login: admin / admin
```

### Option 2: Using Docker Compose Directly

```bash
# 1. Navigate to MongoDB quick-setup
cd docker/quick-setup/mongodb

# 2. Start all services
docker-compose up -d

# 3. Check status
docker-compose ps

# 4. Access the Management Console
# Open browser: http://localhost:8084
# Login: admin / admin
```

### Verify Installation

```bash
# Check all containers are running
docker ps

# Expected output: 6 containers running
# - gio_apim_gateway
# - gio_apim_management_api
# - gio_apim_management_ui
# - gio_apim_portal_ui
# - gio_apim_mongodb
# - gio_apim_elasticsearch
# - gio_apim_mailhog

# Test Gateway health
curl http://localhost:8082/_node/health

# Test Management API
curl http://localhost:8083/management/organizations
```

**🎉 Success!** You now have Gravitee APIM running locally.

---

## Available Setup Options

The repository includes 25+ pre-configured Docker Compose setups for different scenarios:

| Setup | Command | Purpose | Key Features |
|-------|---------|---------|--------------|
| **mongodb** | `make mongodb` | Default setup | MongoDB + Elasticsearch + All UIs |
| **postgresql** | `make postgresql` | PostgreSQL database | PostgreSQL instead of MongoDB |
| **keycloak** | `make keycloak` | Keycloak SSO | OAuth2/OIDC authentication |
| **kibana** | `make kibana` | ELK Stack | Kibana for log visualization |
| **prometheus** | `make prometheus` | Monitoring | Prometheus metrics + Grafana |
| **redis-rate-limit** | `make redis-rate-limit` | Redis caching | Distributed rate limiting |
| **opensearch** | `make opensearch` | OpenSearch | Alternative to Elasticsearch |
| **nginx** | `make nginx` | Reverse proxy | NGINX load balancer |
| **https-gateway** | `make https-gateway` | SSL/TLS | HTTPS enabled gateway |
| **tcp** | `make tcp` | TCP proxy | TCP protocol support |

### Full List of Available Setups

```bash
# Run this to see all options
cd docker
make help
```

**Available setups:**
- `consul-service-discovery` - Consul integration
- `distributed-sync` - Distributed synchronization
- `ee-with-alert-engine` - Enterprise Edition with alerts
- `eureka-service-discovery` - Eureka integration
- `gateway-http-bridge-repository` - Bridge mode
- `kafka-console` - Kafka integration
- `native-kafka` - Native Kafka support
- `opentelemetry-jaeger` - OpenTelemetry tracing
- `systemProxy` - System proxy configuration
- `tags-internal-external` - Multi-gateway with tags
- And more...

---

## Detailed Setup Instructions

### 1. Basic MongoDB Setup (Default)

**Best for:** Development, testing, learning Gravitee APIM

**What's included:**
- API Gateway (Port 8082)
- Management API (Port 8083)
- Management Console UI (Port 8084)
- Developer Portal UI (Port 4100)
- MongoDB (Port 27017)
- Elasticsearch 8.17 (Port 9200)
- MailHog email server (Port 8025)

**Steps:**

```bash
# Navigate to directory
cd docker/quick-setup/mongodb

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose stop

# Remove everything (including data)
docker-compose down -v
```

**Using Makefile:**

```bash
cd docker

# Start
make mongodb

# Stop
make stop TARGET=mongodb

# Remove
make down TARGET=mongodb
```

**Configuration:**
- Default images: `graviteeio/apim-*:latest`
- Database: MongoDB 6.0
- Analytics: Elasticsearch 8.17.2

---

### 2. PostgreSQL Setup

**Best for:** Testing SQL database backend, production-like setup

**What's different:**
- Uses PostgreSQL instead of MongoDB
- All management data stored in PostgreSQL
- Analytics still use Elasticsearch

**Steps:**

```bash
cd docker/quick-setup/postgresql

# Start services
docker-compose up -d

# Access PostgreSQL
docker exec -it gio_apim_postgresql psql -U postgres -d gravitee

# View tables
\dt
```

**Database connection:**
- Host: localhost
- Port: 5432
- Database: gravitee
- User: postgres
- Password: (check docker-compose.yml)

---

### 3. Keycloak Setup (OAuth2/OIDC Authentication)

**Best for:** Testing SSO, OAuth2 authentication, enterprise auth

**What's included:**
- Keycloak 26.2.0 (Port 8080)
- Pre-configured realm: "gio"
- NGINX reverse proxy for auth endpoints
- OAuth2 resource plugin for Keycloak
- All standard components

**Steps:**

```bash
cd docker/quick-setup/keycloak

# Create license directory (if using Enterprise features)
mkdir -p .license
# Optional: Copy your license file to .license/

# Start services
docker-compose up -d

# View logs
docker-compose logs -f keycloak
```

**Access Keycloak:**
- URL: http://localhost:8080
- Realm: "gio"
- Pre-configured client ID: `gravitee-client`
- Client secret: `00dc0118-2a0d-4249-86a3-3e133f5de145`

**Testing OAuth2 Flow:**

```bash
# 1. Get access token from Keycloak
curl --location --request POST 'http://localhost:8080/realms/gio/protocol/openid-connect/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id=gravitee-client' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_secret=00dc0118-2a0d-4249-86a3-3e133f5de145'

# 2. Use token to call API
curl --location --request GET 'http://localhost:8082/your-api' \
--header 'Authorization: Bearer <your-token>'
```

**Create users in Keycloak:**
1. Access http://localhost:8080
2. Navigate to "gio" realm
3. Users → Add User
4. Set credentials
5. Login to Management Console with Keycloak

---

### 4. Kibana Setup (ELK Stack)

**Best for:** Log analysis, analytics visualization, debugging

**What's included:**
- Kibana 8.17.2 (Port 5601)
- Connected to Elasticsearch
- Pre-configured for Gravitee indices
- All standard components

**Steps:**

```bash
cd docker/quick-setup/kibana

# Start services
docker-compose up -d

# Wait for Kibana to be ready (can take 1-2 minutes)
docker-compose logs -f kibana

# Access Kibana
# Browser: http://localhost:5601
```

**Using Kibana:**

1. **Create Index Pattern:**
   - Go to Management → Stack Management → Index Patterns
   - Create pattern: `gravitee*`
   - Time field: `@timestamp`

2. **View Logs:**
   - Go to Analytics → Discover
   - Select `gravitee*` index pattern
   - Filter by API, application, or time range

3. **Create Dashboards:**
   - Go to Analytics → Dashboard
   - Create visualizations for:
     - Request count over time
     - Response time percentiles
     - Error rate by API
     - Top APIs by traffic

**Available Gravitee Indices:**
- `gravitee-request-*` - API request logs
- `gravitee-health-*` - Health check data
- `gravitee-monitor-*` - Gateway monitoring
- `gravitee-log-*` - Application logs

---

### 5. Prometheus Setup (Monitoring)

**Best for:** Metrics collection, monitoring, alerting

**What's included:**
- Prometheus (Port 9090)
- Grafana (check docker-compose for port)
- Pre-configured scrape configs for Gateway
- All standard components

**Steps:**

```bash
cd docker/quick-setup/prometheus

# Start services
docker-compose up -d

# Access Prometheus
# Browser: http://localhost:9090

# Access Grafana
# Browser: http://localhost:3000 (check docker-compose.yml)
# Default credentials: admin / admin
```

**Gateway Metrics Endpoint:**
- URL: http://localhost:8082/_node/metrics/prometheus
- Format: Prometheus text format
- Metrics include: JVM, HTTP requests, response times, GC stats

**Sample Prometheus Queries:**

```promql
# Request rate
rate(http_requests_total[5m])

# Response time 95th percentile
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# JVM memory usage
jvm_memory_used_bytes / jvm_memory_max_bytes

# Error rate
rate(http_requests_total{status=~"5.."}[5m])
```

---

### 6. Redis Rate Limit Setup

**Best for:** Distributed rate limiting, high-performance caching

**What's included:**
- Redis 6.0+ (Port 6379)
- Gateway configured to use Redis for rate limiting
- All standard components

**Steps:**

```bash
cd docker/quick-setup/redis-rate-limit

# Start services
docker-compose up -d

# Access Redis CLI
docker exec -it gio_apim_redis redis-cli

# View rate limit keys
KEYS *ratelimit*

# Check a specific rate limit value
GET <key>
```

**Benefits:**
- Distributed rate limiting across multiple Gateway nodes
- Atomic operations for quota enforcement
- Better performance than MongoDB/JDBC for rate limits

---

### 7. HTTPS Gateway Setup

**Best for:** Testing SSL/TLS, production-like security

**What's included:**
- Gateway with HTTPS enabled (Port 8443)
- Self-signed certificates
- HTTP to HTTPS redirect
- All standard components

**Steps:**

```bash
cd docker/quick-setup/https-gateway

# Start services
docker-compose up -d

# Access Gateway via HTTPS
curl -k https://localhost:8443/_node/health

# Note: -k flag ignores self-signed certificate warning
```

**Certificate Information:**
- Location: Check docker-compose.yml for volume mounts
- Type: Self-signed (for testing only)
- For production: Replace with valid certificates

---

### 8. OpenSearch Setup

**Best for:** OpenSearch users, Elasticsearch alternative

**What's included:**
- OpenSearch (Port 9200)
- OpenSearch Dashboards (Port 5601)
- Compatible with Gravitee analytics
- All standard components

**Steps:**

```bash
cd docker/quick-setup/opensearch

# Start services
docker-compose up -d

# Access OpenSearch Dashboards
# Browser: http://localhost:5601
```

---

## Custom Configurations

### Creating a Custom Setup

You can create your own custom docker-compose combining features:

```bash
# Create custom directory
mkdir -p docker/quick-setup/custom
cd docker/quick-setup/custom

# Copy base setup (e.g., mongodb)
cp ../mongodb/docker-compose.yml .

# Edit docker-compose.yml to add/modify services
# Example: Add Kibana to MongoDB setup
```

### Example: MongoDB + Keycloak + Kibana

Create `docker/quick-setup/custom/docker-compose.yml`:

```yaml
version: '3.8'

networks:
  frontend:
    name: frontend
  storage:
    name: storage

volumes:
  data-elasticsearch:
  data-mongo:

services:
  mongodb:
    image: mongo:6.0
    container_name: gio_apim_mongodb
    restart: always
    volumes:
      - data-mongo:/data/db
    networks:
      - storage

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.17.2
    container_name: gio_apim_elasticsearch
    restart: always
    volumes:
      - data-elasticsearch:/usr/share/elasticsearch/data
    environment:
      - xpack.security.enabled=false
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    networks:
      - storage

  kibana:
    image: docker.elastic.co/kibana/kibana:8.17.2
    container_name: gio_apim_kibana
    restart: always
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
      - XPACK_SECURITY_ENABLED=false
    networks:
      - storage

  keycloak:
    image: quay.io/keycloak/keycloak:26.2.0
    container_name: gio_apim_keycloak
    restart: always
    ports:
      - "8080:8080"
    environment:
      - KEYCLOAK_ADMIN=admin
      - KEYCLOAK_ADMIN_PASSWORD=admin
      - KC_HTTP_ENABLED=true
      - KC_HOSTNAME_STRICT=false
    command: start-dev
    networks:
      - frontend

  gateway:
    image: graviteeio/apim-gateway:latest
    container_name: gio_apim_gateway
    restart: always
    ports:
      - "8082:8082"
    depends_on:
      - mongodb
      - elasticsearch
    environment:
      - gravitee_management_mongodb_uri=mongodb://mongodb:27017/gravitee
      - gravitee_ratelimit_mongodb_uri=mongodb://mongodb:27017/gravitee
      - gravitee_reporters_elasticsearch_endpoints_0=http://elasticsearch:9200
    networks:
      - storage
      - frontend

  management_api:
    image: graviteeio/apim-management-api:latest
    container_name: gio_apim_management_api
    restart: always
    ports:
      - "8083:8083"
    depends_on:
      - mongodb
      - elasticsearch
    environment:
      - gravitee_management_mongodb_uri=mongodb://mongodb:27017/gravitee
      - gravitee_analytics_elasticsearch_endpoints_0=http://elasticsearch:9200
    networks:
      - storage
      - frontend

  management_ui:
    image: graviteeio/apim-management-ui:latest
    container_name: gio_apim_management_ui
    restart: always
    ports:
      - "8084:8080"
    depends_on:
      - management_api
    environment:
      - MGMT_API_URL=http://localhost:8083/management/
    networks:
      - frontend

  portal_ui:
    image: graviteeio/apim-portal-ui:latest
    container_name: gio_apim_portal_ui
    restart: always
    ports:
      - "4100:8080"
    depends_on:
      - management_api
    environment:
      - PORTAL_API_URL=http://localhost:8083/portal
    networks:
      - frontend
```

**Usage:**

```bash
cd docker/quick-setup/custom
docker-compose up -d
```

---

### Using Specific Versions

```bash
# Set APIM version
export APIM_VERSION=4.10.0

# Start with specific version
docker-compose up -d

# Or using Makefile
make mongodb APIM_VERSION=4.10.0
```

**Available versions:**
- `latest` - Latest stable release
- `nightly` - Nightly builds (bleeding edge)
- `4.10.0`, `4.9.0`, etc. - Specific versions
- `4.10.0-alpha.1` - Pre-release versions

**Check available tags:**
- Gateway: https://hub.docker.com/r/graviteeio/apim-gateway/tags
- Management API: https://hub.docker.com/r/graviteeio/apim-management-api/tags
- Console UI: https://hub.docker.com/r/graviteeio/apim-management-ui/tags
- Portal UI: https://hub.docker.com/r/graviteeio/apim-portal-ui/tags

---

### Enterprise Edition (With License)

For Enterprise Edition features:

```bash
# Set your license key
export LICENSE_KEY="your-base64-encoded-license-key"

# Or create license file
cd docker/quick-setup/mongodb
mkdir -p .license
# Copy your license.key file to .license/

# Start with Enterprise Edition images
export APIM_VERSION=4.10.0
docker-compose up -d

# License will be automatically loaded
```

**Enterprise features require:**
- Valid license file or LICENSE_KEY environment variable
- Enterprise Edition images (no `-ee` suffix needed for latest versions)

---

## Access Information

### Default Ports

| Service | Port | URL | Default Credentials |
|---------|------|-----|---------------------|
| **Gateway** | 8082 | http://localhost:8082 | N/A |
| **Management API** | 8083 | http://localhost:8083 | N/A |
| **Management Console** | 8084 | http://localhost:8084 | admin / admin |
| **Developer Portal** | 4100 | http://localhost:4100 | Register new user |
| **MongoDB** | 27017 | mongodb://localhost:27017 | No auth (local) |
| **Elasticsearch** | 9200 | http://localhost:9200 | No auth (local) |
| **Kibana** | 5601 | http://localhost:5601 | No auth (local) |
| **Keycloak** | 8080 | http://localhost:8080 | admin / admin |
| **Prometheus** | 9090 | http://localhost:9090 | No auth |
| **MailHog UI** | 8025 | http://localhost:8025 | No auth |
| **MailHog SMTP** | 1025 | localhost:1025 | No auth |

### Gateway Endpoints

```bash
# Health check
curl http://localhost:8082/_node/health

# Node information
curl http://localhost:8082/_node

# Prometheus metrics
curl http://localhost:8082/_node/metrics/prometheus

# Monitor endpoint
curl http://localhost:8082/_node/monitor
```

### Management API Endpoints

```bash
# Organizations
curl http://localhost:8083/management/organizations

# User info (requires authentication)
curl -u admin:admin http://localhost:8083/management/user

# Portal configuration
curl http://localhost:8083/portal/environments/DEFAULT
```

### Database Access

**MongoDB:**
```bash
# Connect to MongoDB shell
docker exec -it gio_apim_mongodb mongosh

# Or using connection string
mongosh mongodb://localhost:27017/gravitee

# List collections
use gravitee
show collections

# Query APIs
db.apis.find().pretty()
```

**PostgreSQL (if using PostgreSQL setup):**
```bash
# Connect to PostgreSQL
docker exec -it gio_apim_postgresql psql -U postgres -d gravitee

# List tables
\dt

# Query APIs
SELECT * FROM apis;
```

**Elasticsearch:**
```bash
# Cluster health
curl http://localhost:9200/_cluster/health?pretty

# List indices
curl http://localhost:9200/_cat/indices?v

# Search requests
curl http://localhost:9200/gravitee-request-*/_search?pretty

# Count documents
curl http://localhost:9200/gravitee-*/_count?pretty
```

---

## Useful Commands

### Docker Compose Commands

```bash
# Start all services
docker-compose up -d

# Start and view logs
docker-compose up

# View logs (follow mode)
docker-compose logs -f

# View logs for specific service
docker-compose logs -f gateway

# List running containers
docker-compose ps

# Stop all services (keeps containers)
docker-compose stop

# Stop specific service
docker-compose stop gateway

# Start stopped services
docker-compose start

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart gateway

# Remove containers (keeps volumes)
docker-compose down

# Remove containers and volumes (deletes data)
docker-compose down -v

# Pull latest images
docker-compose pull

# Rebuild images (if using custom Dockerfiles)
docker-compose build

# View resource usage
docker-compose stats
```

### Makefile Commands

```bash
# From docker/ directory

# View help
make help

# Start a setup
make mongodb
make keycloak
make kibana
make prometheus

# Stop a setup
make stop TARGET=mongodb

# Start a stopped setup
make start TARGET=mongodb

# Remove a setup
make down TARGET=mongodb

# Start with specific version
make mongodb APIM_VERSION=4.10.0

# Prepare (create license directory)
make prepare TARGET=mongodb

# Stop specific service
make stop TARGET=mongodb SERVICES=gateway

# Start specific service
make start TARGET=mongodb SERVICES=gateway
```

### Docker Commands

```bash
# List all containers (including stopped)
docker ps -a

# View container logs
docker logs gio_apim_gateway
docker logs -f gio_apim_gateway --tail 100

# Execute command in container
docker exec -it gio_apim_gateway bash

# Copy file from container
docker cp gio_apim_gateway:/opt/graviteeio-gateway/logs/gravitee.log ./

# Copy file to container
docker cp ./config.yml gio_apim_gateway:/opt/graviteeio-gateway/config/

# Inspect container
docker inspect gio_apim_gateway

# View container resource usage
docker stats gio_apim_gateway

# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Remove everything (use with caution!)
docker system prune -a --volumes
```

### Quick Diagnostics

```bash
# Check all services are healthy
docker ps --format "table {{.Names}}\t{{.Status}}"

# Test connectivity
curl http://localhost:8082/_node/health
curl http://localhost:8083/management/organizations
curl http://localhost:9200/_cluster/health

# View Gateway logs for errors
docker logs gio_apim_gateway 2>&1 | grep -i error

# View Management API logs for errors
docker logs gio_apim_management_api 2>&1 | grep -i error

# Check MongoDB connection
docker exec -it gio_apim_mongodb mongosh --eval "db.adminCommand('ping')"

# Check Elasticsearch connection
curl -s http://localhost:9200/_cluster/health | jq .
```

---

## Troubleshooting

### Common Issues

#### 1. Port Already in Use

**Problem:** Error message like "port 8082 is already allocated"

**Solution:**

```bash
# Find what's using the port
lsof -i :8082
# Or on Linux
netstat -tulpn | grep 8082

# Kill the process
kill -9 <PID>

# Or change the port in docker-compose.yml
ports:
  - "8092:8082"  # Use 8092 externally instead
```

#### 2. Containers Won't Start

**Problem:** Containers exit immediately or fail health checks

**Solution:**

```bash
# Check logs for error messages
docker-compose logs

# Check specific service
docker-compose logs gateway

# Check Docker resources
docker info | grep -i memory
docker info | grep -i cpus

# Increase Docker memory (Docker Desktop)
# Settings → Resources → Memory → 8GB

# Remove and recreate
docker-compose down -v
docker-compose pull
docker-compose up -d
```

#### 3. MongoDB Connection Errors

**Problem:** "Connection refused" or "ServerSelectionTimeoutError"

**Solution:**

```bash
# Check MongoDB is running
docker ps | grep mongodb

# Check MongoDB logs
docker logs gio_apim_mongodb

# Test MongoDB connection
docker exec -it gio_apim_mongodb mongosh --eval "db.adminCommand('ping')"

# Restart MongoDB
docker-compose restart mongodb

# Wait for MongoDB to be ready (health check)
docker-compose ps mongodb
```

#### 4. Elasticsearch Yellow/Red Status

**Problem:** Elasticsearch cluster health is yellow or red

**Solution:**

```bash
# Check cluster health
curl http://localhost:9200/_cluster/health?pretty

# For single-node setup, yellow status is normal
# (replicas can't be allocated on single node)

# Increase heap size if out of memory
# In docker-compose.yml:
environment:
  - "ES_JAVA_OPTS=-Xms1g -Xmx1g"

# Check Elasticsearch logs
docker logs gio_apim_elasticsearch
```

#### 5. Gateway Can't Sync APIs

**Problem:** APIs deployed in Console don't appear in Gateway

**Solution:**

```bash
# Check Gateway logs for sync errors
docker logs gio_apim_gateway | grep -i sync

# Check MongoDB connection from Gateway
docker logs gio_apim_gateway | grep -i mongodb

# Verify API exists in MongoDB
docker exec -it gio_apim_mongodb mongosh gravitee --eval "db.apis.count()"

# Check sync service configuration
docker logs gio_apim_gateway | grep "Sync service"

# Restart Gateway
docker-compose restart gateway

# Force sync by restarting both
docker-compose restart management_api gateway
```

#### 6. Unable to Login to Console

**Problem:** "Invalid credentials" or login page won't load

**Solution:**

```bash
# Default credentials
Username: admin
Password: admin

# Check Management API is running
curl http://localhost:8083/management/organizations

# Check Management UI can reach API
docker logs gio_apim_management_ui

# Verify MGMT_API_URL is correct
docker inspect gio_apim_management_ui | grep MGMT_API_URL

# Clear browser cache and cookies
# Try incognito/private window

# Reset admin password in MongoDB
docker exec -it gio_apim_mongodb mongosh gravitee --eval "
db.users.updateOne(
  {username: 'admin'},
  {\$set: {password: '\$2a\$10\$...'}}  // BCrypt hash of 'admin'
)"
```

#### 7. High Memory Usage

**Problem:** Docker consuming too much memory

**Solution:**

```bash
# Check memory usage
docker stats

# Reduce Elasticsearch heap
# In docker-compose.yml:
environment:
  - "ES_JAVA_OPTS=-Xms512m -Xmx512m"

# Reduce MongoDB cache
# In docker-compose.yml:
command: mongod --wiredTigerCacheSizeGB 0.5

# Stop unused services
docker-compose stop portal_ui  # If not using Portal
docker-compose stop mailhog    # If not testing emails

# Clean up unused resources
docker system prune -a --volumes
```

#### 8. Slow Performance

**Problem:** APIs responding slowly, UI laggy

**Solution:**

```bash
# Check resource usage
docker stats

# Increase Docker resources
# Docker Desktop → Settings → Resources
# Memory: 8GB
# CPUs: 4

# Check Gateway logs for timeouts
docker logs gio_apim_gateway | grep -i timeout

# Check Elasticsearch performance
curl http://localhost:9200/_nodes/stats?pretty

# Optimize Elasticsearch
# Reduce refresh interval, disable replicas for local dev

# Use Redis for rate limiting instead of MongoDB
# (redis-rate-limit setup)
```

#### 9. License Issues (Enterprise Edition)

**Problem:** "License expired" or "Invalid license"

**Solution:**

```bash
# Check license environment variable
echo $LICENSE_KEY

# Or check license file exists
ls -la docker/quick-setup/mongodb/.license/

# Verify license is mounted in container
docker inspect gio_apim_gateway | grep -i license

# Set license key
export LICENSE_KEY="your-base64-license-key"

# Or create license file
mkdir -p .license
cp /path/to/license.key .license/

# Restart services
docker-compose down
docker-compose up -d
```

#### 10. Keycloak Integration Issues

**Problem:** Can't login with Keycloak

**Solution:**

```bash
# Check Keycloak is running
curl http://localhost:8080

# Verify realm exists
# Browser: http://localhost:8080
# Check "gio" realm is created

# Test token endpoint
curl --request POST 'http://localhost:8080/realms/gio/protocol/openid-connect/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id=gravitee-client' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_secret=00dc0118-2a0d-4249-86a3-3e133f5de145'

# Check Management API configuration
docker logs gio_apim_management_api | grep -i keycloak

# Verify OIDC settings in Console
# Management Console → Organization → Settings → Authentication
```

---

### Getting Detailed Logs

```bash
# All logs with timestamps
docker-compose logs -f --timestamps

# Last 100 lines
docker-compose logs --tail 100

# Logs since specific time
docker-compose logs --since 2026-01-03T10:00:00

# Export logs to file
docker-compose logs > gravitee-logs.txt

# Logs for specific service with grep
docker logs gio_apim_gateway 2>&1 | grep -i "error\|exception\|fail"
```

### Health Checks

```bash
# Gateway health
curl -f http://localhost:8082/_node/health || echo "Gateway unhealthy"

# Management API health
curl -f http://localhost:8083/management/organizations || echo "Management API unhealthy"

# MongoDB health
docker exec gio_apim_mongodb mongosh --eval "db.adminCommand('ping')" || echo "MongoDB unhealthy"

# Elasticsearch health
curl -f http://localhost:9200/_cluster/health || echo "Elasticsearch unhealthy"

# All health checks
#!/bin/bash
echo "Checking Gateway..."; curl -sf http://localhost:8082/_node/health > /dev/null && echo "✓ Gateway OK" || echo "✗ Gateway FAILED"
echo "Checking Management API..."; curl -sf http://localhost:8083/management/organizations > /dev/null && echo "✓ Management API OK" || echo "✗ Management API FAILED"
echo "Checking Elasticsearch..."; curl -sf http://localhost:9200/_cluster/health > /dev/null && echo "✓ Elasticsearch OK" || echo "✗ Elasticsearch FAILED"
echo "Checking MongoDB..."; docker exec gio_apim_mongodb mongosh --quiet --eval "db.adminCommand('ping').ok" | grep -q 1 && echo "✓ MongoDB OK" || echo "✗ MongoDB FAILED"
```

---

## Advanced Topics

### Building from Source

If you want to run locally-built images instead of pulling from Docker Hub:

```bash
# Build the project
cd /Users/mohammad/Sites/github.com/gravitee-io/gravitee-api-management
mvn clean install -DskipTests

# Build Docker images
cd gravitee-apim-gateway/gravitee-apim-gateway-standalone/gravitee-apim-gateway-standalone-distribution
docker build -t graviteeio/apim-gateway:local .

cd ../../../gravitee-apim-rest-api/gravitee-apim-rest-api-standalone/gravitee-apim-rest-api-standalone-distribution
docker build -t graviteeio/apim-management-api:local .

# Update docker-compose.yml to use local images
# Change image tags to :local
gateway:
  image: graviteeio/apim-gateway:local

management_api:
  image: graviteeio/apim-management-api:local

# Start with local images
docker-compose up -d
```

### Custom Plugin Development

```bash
# Create plugin directory
mkdir -p docker/quick-setup/custom-plugins

# Mount plugin directory in docker-compose.yml
gateway:
  volumes:
    - ./custom-plugins:/opt/graviteeio-gateway/plugins

# Copy your plugin JAR
cp /path/to/your-plugin.zip docker/quick-setup/custom-plugins/

# Restart Gateway
docker-compose restart gateway

# Check plugin is loaded
docker logs gio_apim_gateway | grep -i plugin
```

### Multi-Gateway Setup

```bash
# Use distributed-sync setup for multiple gateways
cd docker/quick-setup/distributed-sync

# Or tags-internal-external for gateway with sharding
cd docker/quick-setup/tags-internal-external

# Start
docker-compose up -d

# Check both gateways are running
docker ps | grep gateway
```

### Data Persistence

**Volumes are persistent by default:**

```bash
# List volumes
docker volume ls | grep gravitee

# Backup MongoDB data
docker exec gio_apim_mongodb mongodump --out /tmp/backup
docker cp gio_apim_mongodb:/tmp/backup ./mongodb-backup

# Restore MongoDB data
docker cp ./mongodb-backup gio_apim_mongodb:/tmp/backup
docker exec gio_apim_mongodb mongorestore /tmp/backup

# Backup Elasticsearch indices
curl -X PUT "http://localhost:9200/_snapshot/backup_repo" \
  -H 'Content-Type: application/json' \
  -d '{"type": "fs", "settings": {"location": "/tmp/backup"}}'

# Remove all data (fresh start)
docker-compose down -v
docker-compose up -d
```

### Environment Variables

Common environment variables you can customize:

```bash
# Gateway
- gravitee_management_mongodb_uri
- gravitee_ratelimit_mongodb_uri
- gravitee_reporters_elasticsearch_endpoints_0
- gravitee_services_sync_cron
- gravitee_services_sync_delay
- gravitee_http_port

# Management API
- gravitee_management_mongodb_uri
- gravitee_analytics_elasticsearch_endpoints_0
- gravitee_email_enabled
- gravitee_email_host
- gravitee_jwt_secret

# UIs
- MGMT_API_URL
- PORTAL_API_URL

# Database versions
- MONGODB_VERSION
- ELASTIC_VERSION
- APIM_VERSION
```

---

## Best Practices

### For Development

1. **Use Docker Compose directly** for faster iteration
2. **Mount local volumes** for logs and debugging
3. **Use latest or nightly** images for bleeding edge features
4. **Enable debug logging** via environment variables
5. **Use MailHog** for email testing (included by default)

### For Testing

1. **Use specific version tags** for reproducibility
2. **Create custom setups** combining needed features
3. **Use Redis** for rate limiting in multi-gateway tests
4. **Enable Prometheus** for performance testing
5. **Use Kibana** for log analysis

### For Production-Like Testing

1. **Use PostgreSQL** instead of MongoDB
2. **Enable HTTPS** on Gateway
3. **Use Redis** for distributed sync and rate limiting
4. **Enable Keycloak** for authentication
5. **Monitor with Prometheus + Grafana**
6. **Set resource limits** in docker-compose.yml

### Resource Management

```yaml
# Add to services in docker-compose.yml
gateway:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 2G
      reservations:
        cpus: '1'
        memory: 1G
```

---

## Quick Reference

### One-Line Commands

```bash
# Start MongoDB setup
cd docker && make mongodb

# Start with Keycloak
cd docker && make keycloak

# Stop everything
cd docker && make down TARGET=mongodb

# View logs
docker-compose -f docker/quick-setup/mongodb/docker-compose.yml logs -f

# Health check all services
curl http://localhost:8082/_node/health && curl http://localhost:8083/management/organizations && curl http://localhost:9200/_cluster/health

# Reset everything
cd docker/quick-setup/mongodb && docker-compose down -v && docker-compose pull && docker-compose up -d

# Quick status check
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Useful Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
alias gravitee-start='cd ~/Sites/github.com/gravitee-io/gravitee-api-management/docker && make mongodb'
alias gravitee-stop='cd ~/Sites/github.com/gravitee-io/gravitee-api-management/docker && make stop TARGET=mongodb'
alias gravitee-logs='docker-compose -f ~/Sites/github.com/gravitee-io/gravitee-api-management/docker/quick-setup/mongodb/docker-compose.yml logs -f'
alias gravitee-status='docker ps --format "table {{.Names}}\t{{.Status}}" | grep gio_apim'
alias gravitee-reset='cd ~/Sites/github.com/gravitee-io/gravitee-api-management/docker/quick-setup/mongodb && docker-compose down -v && docker-compose up -d'
```

---

## Getting Help

### Documentation

- **Official Docs:** https://documentation.gravitee.io/apim
- **Architecture Guide:** See `ARCHITECTURE.md` in repository root
- **Docker Setups:** `docker/quick-setup/*/README.md`

### Community

- **GitHub Issues:** https://github.com/gravitee-io/gravitee-api-management/issues
- **Community Forum:** https://community.gravitee.io
- **Slack:** https://gravitee.io/slack

### Logs Location

```bash
# Container logs
docker logs gio_apim_gateway
docker logs gio_apim_management_api

# Mounted log volumes (if configured)
ls -la /var/lib/docker/volumes/mongodb_apim-gateway-logs/_data/
ls -la /var/lib/docker/volumes/mongodb_apim-management-api-logs/_data/
```

---

## Conclusion

This guide covers all the common ways to run Gravitee APIM locally using Docker. Choose the setup that best matches your needs:

- **Learning/Testing:** MongoDB setup
- **Keycloak Integration:** Keycloak setup
- **Log Analysis:** Kibana setup
- **Monitoring:** Prometheus setup
- **Custom Needs:** Create custom docker-compose

For production deployments, see the official documentation and Kubernetes Helm charts in `helm/`.

**Happy API Management! 🚀**

---

**Last Updated:** 2026-01-03
**Maintained By:** Your Team
**Repository:** https://github.com/gravitee-io/gravitee-api-management
