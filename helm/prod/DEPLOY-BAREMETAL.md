# Gravitee APIM — Bare-Metal (kubeadm) Deployment Runbook

Follow-along deploy for a vanilla **kubeadm** cluster (3–4 nodes), single-node data layer,
traffic path **MetalLB → ingress-nginx → Ingress → Service → pod**, TLS at ingress-nginx.

This mirrors the validated kind "prod-mirror" (`helm/kind/`). The **only** differences vs. kind:
nodes pull images directly from registries (no `kind load`), you use a **real LAN IP range** for
MetalLB and **real DNS**, and TLS is a real cert (cert-manager or your CA) instead of self-signed.

Versions: chart `apim` 4.11.0 · images 4.11.6 · MetalLB v0.14.8 · ingress-nginx controller-v1.11.3.

---

## 0. Prerequisites (verify BEFORE starting)

```bash
kubectl config current-context          # must be your PROD cluster — double-check this
kubectl get nodes                        # all Ready (1 control-plane + 2-3 workers)
helm version                             # v3.x
kubectl get storageclass                 # a DEFAULT (marked "(default)") node-local SC must exist
```
Also confirm: cluster egress to `docker.io`, `quay.io`, `registry.k8s.io`; a **spare LAN IP range**
for MetalLB; **DNS** you can point at a VIP; and a TLS cert path (cert-manager OR cert+key files).

---

## 1. Fill the placeholders (set once, reused by every command below)

```bash
export HOST=apim.example.com                 # your real API/console hostname
export TLS_SECRET=apim-tls                    # k8s secret holding the cert for $HOST
export NS=gravitee
export LB_RANGE=192.168.10.240-192.168.10.250 # spare LAN IPs for MetalLB (NOT in DHCP scope)
export SC=""                                  # "" = cluster default; else your node-local SC name
export KUBE=""                                # optional: "--kube-context <prod-ctx>" for safety
```
Edit `helm/prod/values-prod.yaml`: replace every `apim.example.com` with `$HOST`. If `$SC` is not
the cluster default, uncomment `persistence.storageClass` under `mongodb` and `elasticsearch.master`.

---

## 2. MetalLB (gives the cluster a LoadBalancer implementation)

```bash
kubectl $KUBE apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
kubectl $KUBE -n metallb-system rollout status deploy/controller --timeout=180s   # wait for webhook

cat <<EOF | kubectl $KUBE apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata: { name: gravitee-pool, namespace: metallb-system }
spec: { addresses: [ "$LB_RANGE" ] }
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata: { name: gravitee-l2, namespace: metallb-system }
spec: { ipAddressPools: [ gravitee-pool ] }
EOF
```
Watch: `kubectl $KUBE -n metallb-system get pods` (1 controller + 1 speaker per node, all Running).

---

## 3. ingress-nginx as a LoadBalancer

```bash
kubectl $KUBE apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/baremetal/deploy.yaml
kubectl $KUBE -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=180s

# type LoadBalancer -> MetalLB assigns a VIP; Local preserves the real client IP (needed by the gateway)
kubectl $KUBE -n ingress-nginx patch svc ingress-nginx-controller \
  -p '{"spec":{"type":"LoadBalancer","externalTrafficPolicy":"Local"}}'

# capture the assigned VIP:
kubectl $KUBE -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}'
```
Note the VIP (e.g. `192.168.10.240`) — call it `$VIP`.

---

## 4. DNS

Point `$HOST` at `$VIP` (A record on your DNS, or `/etc/hosts` on client machines for a first test):
```bash
# quick local test from a client:  echo "$VIP $HOST" | sudo tee -a /etc/hosts
```

---

## 5. TLS secret `$TLS_SECRET` (pick ONE)

```bash
kubectl $KUBE create namespace $NS --dry-run=client -o yaml | kubectl $KUBE apply -f -
```

**Option A — cert-manager** (create ONE Certificate; do NOT put cluster-issuer annotations on the
5 ingresses — they'd each spawn a Certificate fighting over the same secret):
```bash
cat <<EOF | kubectl $KUBE apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: { name: apim-tls, namespace: $NS }
spec:
  secretName: $TLS_SECRET
  dnsNames: [ "$HOST" ]
  issuerRef: { name: <your-clusterissuer>, kind: ClusterIssuer }
EOF
kubectl $KUBE -n $NS wait --for=condition=Ready certificate/apim-tls --timeout=180s
```

**Option B — bring your own cert:**
```bash
kubectl $KUBE -n $NS create secret tls $TLS_SECRET --cert=tls.crt --key=tls.key
```

---

## 6. Deploy

```bash
cd <repo-root>
helm dependency build helm/                       # fetch ES + Mongo subcharts (once)

helm install apim helm/ -n $NS --create-namespace $KUBE \
  -f helm/deploy/values-common.yaml \
  -f helm/prod/values-prod.yaml
```
Upgrade later with the same `-f` set: `helm upgrade apim helm/ -n $NS $KUBE -f ... -f ...`.

---

## 7. Watch it come up

```bash
# live pod view (Ctrl-C to stop):
kubectl $KUBE -n $NS get pods -w

# or block until each workload is ready:
kubectl $KUBE -n $NS rollout status statefulset/graviteeio-apim-elasticsearch-master --timeout=300s
kubectl $KUBE -n $NS rollout status statefulset/graviteeio-apim-mongodb-replicaset   --timeout=300s
kubectl $KUBE -n $NS rollout status deploy/apim-api     --timeout=300s
kubectl $KUBE -n $NS rollout status deploy/apim-gateway --timeout=300s

# one-line readiness loop:
until [ "$(kubectl $KUBE -n $NS get pods --no-headers | awk '$2=="1/1"{c++} END{print c+0}')" = 6 ]; do \
  kubectl $KUBE -n $NS get pods --no-headers | awk '{print $1,$2,$3}'; echo '---'; sleep 10; done
```

---

## 8. Verify (data layer + full traffic path)

```bash
# pods 1/1 and their node spread:
kubectl $KUBE -n $NS get pods -o wide

# PVCs Bound:
kubectl $KUBE -n $NS get pvc

# Elasticsearch: expect "status":"green"
kubectl $KUBE -n $NS exec graviteeio-apim-elasticsearch-master-0 -- \
  curl -s localhost:9200/_cluster/health | tr ',' '\n' | grep -E 'status|number_of_nodes'

# MongoDB: expect PRIMARY
kubectl $KUBE -n $NS exec graviteeio-apim-mongodb-replicaset-0 -- \
  mongosh --quiet --eval 'rs.status().members[0].stateStr'

# Full path over TLS via the real hostname (expect HTTP 200):
curl -sk https://$HOST/management/v2/ui/bootstrap -o /dev/null -w 'bootstrap: %{http_code}\n'
curl -sk https://$HOST/console/                   -o /dev/null -w 'console:   %{http_code}\n'
curl -sk https://$HOST/devportal/                 -o /dev/null -w 'devportal: %{http_code}\n'
```
Then open `https://$HOST/console/` in a browser (default login `admin` / `admin`).

Debug helpers if something is not Ready:
```bash
kubectl $KUBE -n $NS describe pod <pod>            # events (scheduling, pull, probe failures)
kubectl $KUBE -n $NS logs deploy/apim-api --tail=200 | grep -iE 'error|mongo|elasticsearch'
kubectl $KUBE -n $NS get events --sort-by=.lastTimestamp | tail -20
```

---

## 9. Post-install (do NOT skip)

- **Change the admin password** immediately (Console → Organization → Users).
- **Backups** — the data layer is single-node (SPOF by design); recovery IS backups:
  - Mongo: schedule `mongodump` → off-cluster S3.
  - ES: register an S3 snapshot repository and schedule snapshots.
- Confirm client-IP works (`externalTrafficPolicy: Local` from step 3) if you use IP-based rate-limit/allow-list plans.

---

## 10. Upgrade / rollback / uninstall

```bash
helm upgrade  apim helm/ -n $NS $KUBE -f helm/deploy/values-common.yaml -f helm/prod/values-prod.yaml
helm history  apim -n $NS $KUBE
helm rollback apim <REVISION> -n $NS $KUBE
helm uninstall apim -n $NS $KUBE            # NOTE: PVCs are retained; delete explicitly if intended:
# kubectl $KUBE -n $NS delete pvc --all     # ⚠️ destroys ES + Mongo data
```

---

## 11. Known limitations (accept or address)

- **Single-node data layer** — one ES node, 1-member Mongo RS. A node/disk loss loses that data
  unless restored from backup. This is the confirmed design; HA would need 3× members + anti-affinity.
- **One hostname for everything** — the gateway (`/`) shares `$HOST` with the admin console/API.
  For stronger zoning, split the gateway onto its own host (e.g. `api.$HOST`) and restrict the admin
  host. Also: any published API context-path under `/console`, `/management`, `/portal`, `/devportal`
  collides with the UI ingresses.
- **Gateway L7 only** — gRPC/TCP/mTLS-passthrough APIs can't traverse ingress-nginx; give the gateway
  its own MetalLB `LoadBalancer` Service if you need them.
```
