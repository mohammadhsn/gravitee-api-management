# Gravitee APIM - Docker Quick Reference

> **Quick reference card for running Gravitee APIM with Docker**
>
> For detailed instructions, see `LOCAL_SETUP_GUIDE.md`

---

## 🚀 Quick Start (30 seconds)

```bash
cd docker
make mongodb
# Wait 60 seconds, then open http://localhost:8084
# Login: admin / admin
```

---

## 📦 Available Setups

| Command | What It Does |
|---------|--------------|
| `make mongodb` | Default setup with MongoDB |
| `make postgresql` | PostgreSQL instead of MongoDB |
| `make keycloak` | With Keycloak SSO/OAuth2 |
| `make kibana` | With Kibana for ELK |
| `make prometheus` | With Prometheus monitoring |
| `make redis-rate-limit` | With Redis caching |

**Full list:** Run `make help`

---

## 🎯 Essential Commands

### Start/Stop

```bash
# Start
cd docker && make mongodb

# Stop (keeps data)
make stop TARGET=mongodb

# Remove (deletes data)
make down TARGET=mongodb

# Restart
make stop TARGET=mongodb && make mongodb
```

### Direct Docker Compose

```bash
cd docker/quick-setup/mongodb

# Start
docker-compose up -d

# Stop
docker-compose stop

# Remove
docker-compose down -v

# View logs
docker-compose logs -f
```

---

## 🌐 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Console** | http://localhost:8084 | admin / admin |
| **Portal** | http://localhost:4100 | Register user |
| **Gateway** | http://localhost:8082 | - |
| **API** | http://localhost:8083 | - |
| **Kibana** | http://localhost:5601 | - |
| **Keycloak** | http://localhost:8080 | admin / admin |
| **MailHog** | http://localhost:8025 | - |

---

## 🔍 Health Checks

```bash
# Gateway
curl http://localhost:8082/_node/health

# Management API
curl http://localhost:8083/management/organizations

# Elasticsearch
curl http://localhost:9200/_cluster/health

# MongoDB
docker exec gio_apim_mongodb mongosh --eval "db.adminCommand('ping')"

# All containers status
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---

## 📊 View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker logs -f gio_apim_gateway
docker logs -f gio_apim_management_api

# Last 100 lines
docker logs --tail 100 gio_apim_gateway

# Search for errors
docker logs gio_apim_gateway 2>&1 | grep -i error
```

---

## 🗄️ Database Access

### MongoDB

```bash
# Shell
docker exec -it gio_apim_mongodb mongosh

# In MongoDB shell
use gravitee
show collections
db.apis.find().pretty()
```

### Elasticsearch

```bash
# Cluster health
curl http://localhost:9200/_cluster/health?pretty

# List indices
curl http://localhost:9200/_cat/indices?v

# Search
curl http://localhost:9200/gravitee-*/_search?pretty
```

---

## 🐛 Troubleshooting

### Port already in use

```bash
# Find process
lsof -i :8082

# Kill it
kill -9 <PID>
```

### Reset everything

```bash
cd docker/quick-setup/mongodb
docker-compose down -v
docker-compose pull
docker-compose up -d
```

### Gateway not syncing APIs

```bash
# Restart both
docker-compose restart management_api gateway

# Check logs
docker logs gio_apim_gateway | grep -i sync
```

### Can't login

```bash
# Default: admin / admin

# Check API is reachable
curl http://localhost:8083/management/organizations

# Clear browser cache or use incognito
```

---

## ⚙️ Common Customizations

### Use specific version

```bash
APIM_VERSION=4.10.0 docker-compose up -d

# Or with Makefile
make mongodb APIM_VERSION=4.10.0
```

### Enterprise Edition with License

```bash
# Set license key
export LICENSE_KEY="your-base64-license"

# Or create license file
mkdir -p .license
cp /path/to/license.key .license/

# Start
docker-compose up -d
```

### Custom docker-compose

```bash
# Copy base setup
mkdir -p docker/quick-setup/custom
cp docker/quick-setup/mongodb/docker-compose.yml docker/quick-setup/custom/

# Edit docker-compose.yml
# Add/modify services

# Start
cd docker/quick-setup/custom
docker-compose up -d
```

---

## 📈 Metrics & Monitoring

### Prometheus metrics

```bash
# Gateway metrics
curl http://localhost:8082/_node/metrics/prometheus

# Sample queries
# Request rate: rate(http_requests_total[5m])
# Response time p95: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### Elasticsearch indices

```bash
# Gravitee indices
curl http://localhost:9200/_cat/indices/gravitee*?v

# Request logs
curl http://localhost:9200/gravitee-request-*/_search

# Health checks
curl http://localhost:9200/gravitee-health-*/_search
```

---

## 🔑 Keycloak Testing

### Get OAuth2 token

```bash
curl --request POST 'http://localhost:8080/realms/gio/protocol/openid-connect/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id=gravitee-client' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_secret=00dc0118-2a0d-4249-86a3-3e133f5de145'
```

### Call API with token

```bash
curl http://localhost:8082/your-api \
--header 'Authorization: Bearer <token>'
```

---

## 💾 Backup & Restore

### Backup MongoDB

```bash
docker exec gio_apim_mongodb mongodump --out /tmp/backup
docker cp gio_apim_mongodb:/tmp/backup ./mongodb-backup
```

### Restore MongoDB

```bash
docker cp ./mongodb-backup gio_apim_mongodb:/tmp/backup
docker exec gio_apim_mongodb mongorestore /tmp/backup
```

### Fresh start (delete all data)

```bash
docker-compose down -v
docker-compose up -d
```

---

## 🧹 Cleanup

```bash
# Stop and remove containers
docker-compose down

# Also remove volumes (data)
docker-compose down -v

# Remove unused Docker resources
docker system prune

# Remove everything (including images)
docker system prune -a --volumes
```

---

## 🔧 Useful Aliases

Add to `.bashrc` or `.zshrc`:

```bash
alias gstart='cd ~/gravitee-api-management/docker && make mongodb'
alias gstop='cd ~/gravitee-api-management/docker && make stop TARGET=mongodb'
alias glogs='docker-compose -f ~/gravitee-api-management/docker/quick-setup/mongodb/docker-compose.yml logs -f'
alias gstatus='docker ps --format "table {{.Names}}\t{{.Status}}" | grep gio_apim'
alias greset='cd ~/gravitee-api-management/docker/quick-setup/mongodb && docker-compose down -v && docker-compose up -d'
```

---

## 📚 More Information

- **Full Guide:** `LOCAL_SETUP_GUIDE.md`
- **Architecture:** `ARCHITECTURE.md`
- **Official Docs:** https://documentation.gravitee.io/apim
- **Docker Hub:** https://hub.docker.com/u/graviteeio

---

**Pro Tip:** Always check logs first when troubleshooting!

```bash
docker-compose logs -f
```
