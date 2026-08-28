# Gravitee APIM — Bare-Metal (kubeadm) Deployment Runbook

Follow-along deploy for a vanilla **kubeadm** cluster (3–4 nodes), single-node data layer,
traffic path **MetalLB → ingress-nginx → Ingress → Service → pod**, TLS at ingress-nginx.

> **Scope: this runbook deploys Gravitee ONLY.**
> MetalLB and ingress-nginx are **already installed and owned by the platform** on this cluster.
> We do not install, patch, or version them — we *discover* their settings (§2) and make our
> Ingress resources match. The only cluster-wide object we create is the TLS secret, in our own
> namespace. If §2 shows a mismatch, the fix goes in `values-prod.yaml`, not in the edge.

This mirrors the validated kind prod-mirror (`helm/kind/kind-cluster-ha.yaml` — 4 nodes,
MetalLB VIP, baremetal ingress-nginx as `LoadBalancer`, TLS at the controller). Differences vs.
that rehearsal: nodes pull images directly from registries (no `kind load`), the VIP and DNS are
real, TLS is a real cert (cert-manager or your CA) instead of self-signed, and **the edge already
exists** — kind has to build it. Chart layering is identical except the last file; kind adds
`helm/kind/values-kind-ha.yaml` purely to shrink heap/disk/cpu.

Versions: chart `apim` 4.11.0 · images 4.11.6. MetalLB and ingress-nginx versions are whatever the
platform runs — §2 records them, and the annotations we rely on are stable across 1.x.

---

## A. Air-gapped preparation (connected host — skip if the cluster has egress)

The chart reaches the internet in **two independent places**. Both must be closed, and they are
closed by different means.

| # | Dependency | Who fetches it | Fix |
|---|---|---|---|
| 1 | Helm subcharts — Bitnami `elasticsearch` 22.0.13 + `mongodb` 16.5.45 from `charts.bitnami.com` | the **operator's** machine, at `helm dependency build` | ship a **packaged chart** that embeds them (A.1) |
| 2 | Container images — 8 for APIM (`graviteeio/*`, `bitnamilegacy/*`), plus 4 more if you deploy the observability release | the **cluster's** kubelet/containerd, at pod start | mirror to an **internal registry** (A.2) |

Note the split: #1 is never fetched by the cluster, so it does not need cluster egress — only the
machine running `helm`. #2 is the one that genuinely requires the air-gap fix.

> `charts.bitnami.com/bitnami/index.yaml` already returns **403** and resolution silently falls
> back to the OCI mirror `registry-1.docker.io/bitnamicharts`. That is another reason to vendor
> the subcharts rather than resolve them at deploy time.

### A.1 — Build a self-contained chart (one artifact, zero repo access)

```bash
# On a CONNECTED host, from the repo root:
helm dependency build helm/          # fetches the 2 subcharts into helm/charts/
helm package helm/ -d ./dist         # -> ./dist/apim-4.11.0.tgz  (~363 KB, subcharts embedded)
helm package helm/observability/ -d ./dist   # -> ./dist/gravitee-observability-0.1.0.tgz
```
The observability chart has no dependencies of its own, so packaging it is just for symmetry:
both releases then install from a `.tgz` rather than one from a tgz and one from a source dir.
Verify it is genuinely self-contained before carrying it in — render it with the repo config and
cache pointed at empty dirs, so Helm *cannot* consult any repository:
```bash
mkdir -p /tmp/norepo
HELM_REPOSITORY_CONFIG=/tmp/norepo/none.yaml HELM_REPOSITORY_CACHE=/tmp/norepo \
  helm template apim ./dist/apim-4.11.0.tgz \
    -f helm/deploy/values-common.yaml -f helm/prod/values-prod.yaml -f helm/prod/values-airgap.yaml \
  | grep -c 'kind: StatefulSet'      # expect 2 (ES + Mongo) -> subcharts resolved locally
```
Carry the whole `dist/` + `helm/` pair inside (see A.3) -- that is both chart
packages plus all four values files. **Do not run `helm dependency build`
on the inside** — it would try to reach the repo. Install from the `.tgz`, not from `helm/`.

> Why not commit `helm/charts/*.tgz` instead? The repo's root `.gitignore` has `helm/**/*.tgz`, so
> the vendored subcharts are deliberately untracked. If you would rather deploy from a git checkout
> on the inside than carry an artifact, add a narrow exception (`!helm/charts/*.tgz`) and commit the
> two tarballs — that is a repo-convention call, so it is left to you.

### A.2 — Mirror the images to an internal registry

`helm/prod/mirror-images.sh` holds the complete image list (8 for APIM + 4 for the optional
observability release) and handles the retagging.
Pick the mode that matches how isolated the cluster is:

```bash
# One host reaches both the internet and the registry:
helm/prod/mirror-images.sh mirror registry.internal

# Fully separated (sneakernet) — OUTSIDE, then INSIDE:
helm/prod/mirror-images.sh bundle /media/usb/apim-images.tar
shasum -a 256 /media/usb/apim-images.tar
helm/prod/mirror-images.sh push registry.internal /media/usb/apim-images.tar
```
The script pins `--platform linux/amd64` and **fails** if any pulled image is the wrong
architecture — mirroring arm64 images from an Apple Silicon laptop to amd64 prod nodes is the most
common way an air-gapped install dies (`exec format error` at pod start). Override with
`PLATFORM=linux/arm64` if your nodes really are arm64.

Two things the script handles that are easy to get wrong by hand:
- **`apim-portal-ui` ships only as `:latest`** — unpinnable, no version label. It is retagged to
  `4.11.6` in the internal registry, which then becomes the source of truth for that component.
- **Bitnami repo paths must be preserved** (`…/bitnamilegacy/mongodb`, not `…/mongodb`), because
  `global.imageRegistry` only replaces the registry host, not the path.

Then set your registry host in `helm/prod/values-airgap.yaml` (replace `registry.example.internal`
— once under `global.imageRegistry`, once per Gravitee component) and confirm nothing leaks:
```bash
helm template apim ./dist/apim-4.11.0.tgz \
  -f helm/deploy/values-common.yaml -f helm/prod/values-prod.yaml -f helm/prod/values-airgap.yaml \
  | grep -oE 'image: "?[^"]+' | sed -E 's/^image: "?//' | sort -u | grep -v '^registry\.internal/'
# no output = every image is internal
```
If the registry needs auth, create `regcred` in the `gravitee` namespace and uncomment
`global.imagePullSecrets` + the per-component `pullSecrets` lines in `values-airgap.yaml`.

### A.3 — Pack it for transfer

One archive carries everything the Helm side needs. `dist/` holds both chart packages; `helm/`
holds the values files, this runbook, and `mirror-images.sh`:
```bash
tar czf gravitee-baremetal-$(date +%Y%m%d).tar.gz --exclude='.DS_Store' dist helm
```
On the far side it extracts to exactly `dist/` + `helm/`, which is what every command below
assumes as the working directory:
```bash
tar xzf gravitee-baremetal-<date>.tar.gz
```
Sanity-check the extracted copy renders with NO repository access before you rely on it:
```bash
mkdir -p /tmp/norepo
HELM_REPOSITORY_CONFIG=/tmp/norepo/none.yaml HELM_REPOSITORY_CACHE=/tmp/norepo \
  helm template apim ./dist/apim-4.11.0.tgz \
    -f helm/deploy/values-common.yaml -f helm/prod/values-prod.yaml \
    -f helm/prod/values-airgap.yaml -f helm/prod/values-observability.yaml \
  | grep -c '^kind: '                # expect 37
```
⚠️ This archive is ~800 KB and contains **no container images**. Those travel separately via
`mirror-images.sh bundle` (§A.2) and are ~3-4 GB. Both halves must arrive.

---

## 0. Prerequisites (verify BEFORE starting)

```bash
kubectl config current-context          # must be your PROD cluster — double-check this
kubectl get nodes                        # all Ready (1 control-plane + 2-3 workers)
helm version                             # v3.x
kubectl get storageclass                 # a DEFAULT (marked "(default)") node-local SC must exist
```
Also confirm: **DNS** you can point at the existing ingress VIP, and a TLS cert path (cert-manager
OR cert+key files). No MetalLB IP range needed — the platform's pool already backs the ingress
Service. For image/chart access, either cluster egress to `docker.io`, or the air-gap prep in §A
(internal registry + packaged chart) — verify the registry is reachable from the nodes:
```bash
kubectl run reg-probe --rm -it --restart=Never \
  --image=registry.internal/bitnamilegacy/os-shell:12-debian-12-r51 -- true    # must pull + exit 0
```

---

## 1. Fill the placeholders (set once, reused by every command below)

```bash
export HOST=apim.example.com                 # your real API/console hostname
export TLS_SECRET=apim-tls                    # k8s secret holding the cert for $HOST
export NS=gravitee
export SC=""                                  # "" = cluster default; else your node-local SC name
export KUBE=""                                # optional: "--kube-context <prod-ctx>" for safety
export INGRESS_CLASS=nginx                    # ← CONFIRM in §2; may not be "nginx" on this cluster
export INGRESS_NS=ingress-nginx               # ← CONFIRM in §2; platform may use another namespace
```
Edit `helm/prod/values-prod.yaml`: replace every `apim.example.com` with `$HOST`, and every
`ingressClassName: nginx` with `$INGRESS_CLASS` (5 places — api.management, api.portal, gateway, ui,
portal). If `$SC` is not the cluster default, uncomment `persistence.storageClass` under `mongodb`
and `elasticsearch.master`.

---

## 2. Discover the EXISTING edge (read-only — change nothing here)

MetalLB and ingress-nginx are already running and shared with other workloads. Run this block and
keep the output; it tells you what to put in `values-prod.yaml` and what to expect at §7.

```bash
# (a) The ingress class name our Ingresses must reference, and whether it is the default:
kubectl $KUBE get ingressclass -o custom-columns=\
'NAME:.metadata.name,CTRL:.spec.controller,DEFAULT:.metadata.annotations.ingressclass\.kubernetes\.io/is-default-class'

# (b) The controller Service and the VIP MetalLB already gave it — this is our $VIP, we do NOT
#     create a new LoadBalancer:
kubectl $KUBE get svc -A --field-selector spec.type=LoadBalancer \
  -o custom-columns='NS:.metadata.namespace,NAME:.metadata.name,VIP:.status.loadBalancer.ingress[0].ip,POLICY:.spec.externalTrafficPolicy,PORTS:.spec.ports[*].port'

# (c) Controller version + how it was deployed (helm release vs static manifest):
kubectl $KUBE -n $INGRESS_NS get deploy -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.template.spec.containers[0].image}{"\n"}{end}'

# (d) Controller-wide settings that override or cap our per-Ingress annotations:
kubectl $KUBE -n $INGRESS_NS get cm -o name | grep -i controller   # then describe it:
kubectl $KUBE -n $INGRESS_NS get cm ingress-nginx-controller -o yaml 2>/dev/null | \
  grep -iE 'proxy-body-size|proxy-read-timeout|proxy-send-timeout|allow-snippet|annotations-risk-level|strict-validate|ssl-redirect|use-forwarded-headers'

# (e) MetalLB pools (informational — confirms a pool exists and has spare IPs if you ever need
#     a dedicated LoadBalancer for the gateway, see §10):
kubectl $KUBE -n metallb-system get ipaddresspool -o custom-columns='NAME:.metadata.name,ADDRESSES:.spec.addresses'
```

**What to check in that output**

| Finding | Action |
|---|---|
| `(a)` class name is not `nginx` | set `$INGRESS_CLASS` and update the 5 `ingressClassName` values |
| `(a)` there is no default class | fine — we set `ingressClassName` explicitly, which is safer on a shared edge |
| `(b)` `POLICY` is `Cluster`, not `Local` | client source IP is **lost**. Do not use IP-based rate-limit/allow-list plans, or ask the platform to enable `Local` / `use-forwarded-headers`. Do **not** patch the shared Service yourself. |
| `(b)` more than one LoadBalancer / class | make sure `$VIP` is the one belonging to `$INGRESS_CLASS` |
| `(d)` `annotations-risk-level` is `Critical`/`High` or `strict-validate` is on | our gateway annotations (`proxy-body-size`, `proxy-*-timeout`) and the portal `rewrite-target` are standard, non-snippet annotations and pass — but confirm the Ingresses are `ACCEPTED` at §7 |
| `(d)` a controller-wide `proxy-body-size` smaller than `50m` | per-Ingress annotation still wins for our hosts; note it if other teams' limits matter |
| `(d)` `ssl-redirect` disabled globally | the http→https 308 in §7 won't happen; decide whether you need it per-Ingress |

---

## 3. DNS

Point `$HOST` at the **existing** `$VIP` from §2(b) — an A record on your DNS, or `/etc/hosts` on a
client machine for a first test:
```bash
export VIP=<from §2(b)>
# quick local test from a client:  echo "$VIP $HOST" | sudo tee -a /etc/hosts
```
Nothing else is needed at the edge: the platform's ingress-nginx already listens on `$VIP:443`, and
our Ingress resources attach to it by `ingressClassName` + `host`.

---

## 4. TLS secret `$TLS_SECRET` (pick ONE)

```bash
kubectl $KUBE create namespace $NS --dry-run=client -o yaml | kubectl $KUBE apply -f -
```

Both options produce the same thing: a `kubernetes.io/tls` secret named `$TLS_SECRET` in `$NS`,
holding a cert valid for `$HOST`. All five ingresses reference that one secret.

> **Air-gapped clusters:** Option A only works with an issuer that needs no internet — a
> cert-manager **CA / Vault issuer backed by your internal PKI**. A public ACME issuer
> (Let's Encrypt) cannot complete a challenge from an isolated cluster. If your PKI is offline
> paperwork, use **Option B**.

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

**Option B — bring your own cert.**

`kubectl create secret tls` does no validation beyond "is this PEM" — a cert that is missing its
intermediates, or whose SAN omits `$HOST`, creates a perfectly healthy-looking secret that then
fails in browsers and in the gateway's own outbound calls. Prepare the two files to spec:

`tls.key` — the **private key**, PEM, **unencrypted** (no passphrase). If yours is encrypted,
kubelet cannot use it; decrypt it first (this prompts for the passphrase):
```bash
openssl pkey -in encrypted.key -out tls.key
```

`tls.crt` — the **full chain**, PEM, in this order, leaf first:
```
-----BEGIN CERTIFICATE-----   <- 1. leaf / server cert for $HOST
-----BEGIN CERTIFICATE-----   <- 2. intermediate CA that signed the leaf
-----BEGIN CERTIFICATE-----   <- 3. further intermediates, if your PKI has them
```
The self-signed root is optional and normally omitted — clients must already trust it. ingress-nginx
serves *exactly* these bytes, so **omitting the intermediates is the single most common mistake**:
browsers with a cached intermediate appear fine while `curl` and Java clients fail with
`unable to get local issuer certificate`.

*B.1 — Request one from your internal CA (the usual air-gapped path).* Generate the key and CSR
yourself; the key never leaves the host:
```bash
openssl req -new -newkey rsa:2048 -nodes \
  -keyout tls.key -out apim.csr \
  -subj "/CN=$HOST/O=YourOrg" \
  -addext "subjectAltName=DNS:$HOST"
```
Hand `apim.csr` to the CA and ask for a **server-auth** cert. Then assemble the chain from what they
return — some CAs hand back leaf and intermediates as separate files, and some silently drop the SAN
you requested, so verify it below:
```bash
cat apim-leaf.crt intermediate-ca.crt > tls.crt
```

*B.2 — Convert an existing PKCS#12 / PFX* (common when the cert comes from a Windows CA). Add
`-legacy` on OpenSSL 3 if the PFX uses old RC2 encryption:
```bash
openssl pkcs12 -in apim.pfx -nocerts -nodes  | openssl pkey  -out tls.key   # key, normalised
openssl pkcs12 -in apim.pfx -clcerts -nokeys | openssl x509  -out leaf.crt  # leaf only
openssl pkcs12 -in apim.pfx -cacerts -nokeys -out chain.crt                 # intermediates
cat leaf.crt chain.crt > tls.crt
```

*B.3 — Self-signed* — **non-production only** (every client shows a warning; the gateway's own
HTTPS calls will reject it unless you also distribute the cert):
```bash
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=$HOST" -addext "subjectAltName=DNS:$HOST"
```

**Verify BEFORE creating the secret** — all four must pass:
```bash
# 1. key actually matches the cert (works for RSA and EC) — the two hashes must be IDENTICAL
openssl x509 -in tls.crt -noout -pubkey | openssl sha256
openssl pkey -in tls.key -pubout       | openssl sha256

# 2. SAN contains $HOST — a matching CN alone is NOT enough for modern browsers
openssl x509 -in tls.crt -noout -ext subjectAltName

# 3. chain is present and in the right order (leaf first, then CAs — expect 2+ certs)
openssl crl2pkcs7 -nocrl -certfile tls.crt | openssl pkcs7 -print_certs -noout

# 4. not expired / not yet valid
openssl x509 -in tls.crt -noout -dates
```

Then create the secret:
```bash
kubectl $KUBE -n $NS create secret tls $TLS_SECRET --cert=tls.crt --key=tls.key
```

To rotate later, replace it in place and the controller picks it up within seconds — no redeploy:
```bash
kubectl $KUBE -n $NS create secret tls $TLS_SECRET \
  --cert=tls.crt --key=tls.key --dry-run=client -o yaml | kubectl $KUBE apply -f -
```

After §5, confirm what the controller actually serves — this is the real test of chain completeness,
because it inspects the wire, not your files:
```bash
openssl s_client -connect $VIP:443 -servername $HOST </dev/null 2>/dev/null | \
  openssl x509 -noout -subject -issuer -dates
# and the full chain as served, with the trust verdict:
openssl s_client -connect $VIP:443 -servername $HOST -showcerts </dev/null 2>&1 | \
  grep -E 'depth=|s:|i:|Verify return code'
```
`Verify return code: 0 (ok)` from a host that trusts your CA means the chain is complete.
`unable to get local issuer certificate` means an intermediate is missing from `tls.crt`.

---

## 5. Deploy

**Connected cluster** (resolves subcharts + images from the internet):
```bash
cd <repo-root>
helm dependency build helm/                       # fetch ES + Mongo subcharts (once)

helm install apim helm/ -n $NS --create-namespace $KUBE \
  -f helm/deploy/values-common.yaml \
  -f helm/prod/values-prod.yaml
```

**Air-gapped cluster** — install from the packaged artifact built in §A.1 and add the airgap
overlay. Note it is `./dist/apim-4.11.0.tgz`, **not** `helm/`: pointing at the source dir would make
Helm try to resolve the subcharts from the network again.
```bash
helm install apim ./dist/apim-4.11.0.tgz -n $NS --create-namespace $KUBE \
  -f helm/deploy/values-common.yaml \
  -f helm/prod/values-prod.yaml \
  -f helm/prod/values-airgap.yaml
```
Upgrade later with the same chart reference and `-f` set:
```bash
helm upgrade apim ./dist/apim-4.11.0.tgz -n $NS $KUBE -f ... -f ...
```
⚠️ Keep the `-f` list identical on every upgrade. Helm values are **replaced, not merged**, across
invocations: dropping `values-airgap.yaml` silently reverts every image to `docker.io` and the next
pod restart hangs in `ImagePullBackOff`; dropping `values-observability.yaml` (§5b) silently turns
the metrics endpoints back off and every Prometheus target goes DOWN. Keep the full list in a
shell variable or a small wrapper script so it cannot be forgotten:
```bash
FILES="-f helm/deploy/values-common.yaml -f helm/prod/values-prod.yaml"
FILES="$FILES -f helm/prod/values-airgap.yaml"          # air-gapped only
FILES="$FILES -f helm/prod/values-observability.yaml"   # if you deploy §5b
helm upgrade apim ./dist/apim-4.11.0.tgz -n $NS $KUBE $FILES
```

---

## 5b. Observability — OPTIONAL (Prometheus, Grafana, Kibana, Logstash)

Skip this whole section if the platform already provides metrics and dashboards — that is usually
the better answer on a shared cluster, and in that case just ask them to scrape the two endpoints
enabled in step 1 below. Full detail in `helm/observability/README.md`.

**Step 1 — expose the Gravitee metrics endpoints** (changes the APIM release):
```bash
helm upgrade apim ./dist/apim-4.11.0.tgz -n $NS $KUBE \
  -f helm/deploy/values-common.yaml \
  -f helm/prod/values-prod.yaml \
  -f helm/prod/values-observability.yaml       # ← added
```
This is not optional for scraping, and it does three separate things — miss any one and the target
is simply `DOWN` with no useful error:
1. `services.metrics.enabled: true` — the Prometheus registry itself
2. `services.core.http.host: 0.0.0.0` — the **management API defaults to `localhost`**, so a scrape
   from another pod connects and gets nothing. The gateway already defaults to `0.0.0.0`.
3. `services.core.service.enabled: true` (+ an explicit `externalPort`) — puts the node API port on
   the ClusterIP Service

Confirm the ports appeared:
```bash
kubectl $KUBE -n $NS get svc apim-api apim-gateway \
  -o custom-columns='NAME:.metadata.name,PORTS:.spec.ports[*].port'
# expect apim-api ... 83,18083   and   apim-gateway ... 82,18082
```

**Step 2 — deploy the companion release** into the same namespace:
```bash
helm install obs ./dist/gravitee-observability-0.1.0.tgz -n $NS $KUBE \
  --set ingress.host=$HOST \
  --set ingress.ingressClassName=$INGRESS_CLASS \
  --set ingress.tls.secretName=$TLS_SECRET \
  --set grafana.adminPassword='<choose-one>'
  # air-gapped: --set global.imageRegistry=registry.internal
```
It is a **separate release** on purpose — the Gravitee chart is upstream and gets bumped, so these
workloads live outside it and never cause merge conflicts.

Adds three paths on the same host, alongside `/console` and `/devportal`:
`$HOST/prometheus`, `$HOST/grafana`, `$HOST/kibana`.

```bash
# both scrape targets must be UP:
kubectl $KUBE -n $NS port-forward svc/obs-observability-prometheus 9090:9090
#   -> http://localhost:9090/prometheus/targets   (gio-gateway, gio-mgmt-api)
```
`connection refused` = step 1 items 2 or 3 missing. `401` = the node-API password in
`targets.auth.password` disagrees with the APIM release.

⚠️ **Logstash defaults to OFF and should stay off unless you have a log shipper.** Its only input
is `beats` on 5044 and there is deliberately no Filebeat here — container stdout is already
collected by a platform agent IF your cluster runs one -- verify, do not assume. Gravitee's analytics never travelled
through Logstash; the gateway's Elasticsearch reporter writes straight to the `gravitee-*` indices.

⚠️ **Two default credentials** — the node API (`admin`/`adminadmin`) and Grafana (`admin`/`admin`).
Change both. And note these three paths share the Console's host, so anyone who can reach the
Console reaches Grafana's login page; put them on an internal host or restrict by source IP if that
is not acceptable.

---

## 6. Watch it come up

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

## 7. Verify (data layer + full traffic path)

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

# All 5 Ingresses picked up by the SHARED controller — ADDRESS must be populated ($VIP) and
# the class must be $INGRESS_CLASS. An empty ADDRESS = the controller ignored us (wrong class):
kubectl $KUBE -n $NS get ingress \
  -o custom-columns='NAME:.metadata.name,CLASS:.spec.ingressClassName,HOST:.spec.rules[0].host,TLS:.spec.tls[0].secretName,ADDRESS:.status.loadBalancer.ingress[0].ip'

# Confirm the controller actually accepted them (no rejected-annotation / conflict events):
kubectl $KUBE -n $NS get events --field-selector reason=Sync | tail -10
kubectl $KUBE -n $NS describe ingress apim-gateway | sed -n '/Events:/,$p'

# Full path over TLS via the real hostname (expect HTTP 200):
curl -sk https://$HOST/management/v2/ui/bootstrap -o /dev/null -w 'bootstrap: %{http_code}\n'
curl -sk https://$HOST/console/                   -o /dev/null -w 'console:   %{http_code}\n'
curl -sk https://$HOST/devportal/                 -o /dev/null -w 'devportal: %{http_code}\n'

# bootstrap must advertise https + the real host (proves the scheme/host values took effect):
curl -sk https://$HOST/management/v2/ui/bootstrap        # -> "baseURL": "https://$HOST/management"

# http -> https redirect (only if the platform leaves ssl-redirect on, see §2(d)):
curl -s -o /dev/null -w 'redirect: %{http_code} -> %{redirect_url}\n' http://$HOST/console/

# Gateway registered with the Management API (proves the event-based sync works):
TOKEN=$(curl -sk -X POST -u admin:admin https://$HOST/management/organizations/DEFAULT/user/login \
  | grep -o '"token" : "[^"]*"' | cut -d'"' -f4)
curl -sk -H "Authorization: Bearer $TOKEN" \
  https://$HOST/management/organizations/DEFAULT/environments/DEFAULT/instances | head -20
```
Then open `https://$HOST/console/` in a browser (default login `admin` / `admin`).

If the curl checks fail but pods are 1/1, the problem is almost always at the shared edge:
wrong `ingressClassName` (empty ADDRESS above), DNS not pointing at `$VIP`, or the TLS secret
missing/mismatched for `$HOST`. Nothing to fix in the platform's controller — check §1 and §2.

Debug helpers if something is not Ready:
```bash
kubectl $KUBE -n $NS describe pod <pod>            # events (scheduling, pull, probe failures)
kubectl $KUBE -n $NS logs deploy/apim-api --tail=200 | grep -iE 'error|mongo|elasticsearch'
kubectl $KUBE -n $NS get events --sort-by=.lastTimestamp | tail -20
```

---

## 8. Post-install (do NOT skip)

- **Change the admin password** immediately (Console → Organization → Users).
- **Backups** — the data layer is single-node (SPOF by design); recovery IS backups:
  - Mongo: schedule `mongodump` → off-cluster S3.
  - ES: register an S3 snapshot repository and schedule snapshots.
- Confirm client-IP works if you use IP-based rate-limit/allow-list plans — it depends on the
  platform's `externalTrafficPolicy` recorded in §2(b), which is **not ours to change**. If it is
  `Cluster`, every request appears to come from a node IP; raise it with the platform team rather
  than patching the shared Service.
- Tell the platform team that `$HOST` now resolves to their shared VIP and which `ingressClassName`
  we attached to — a shared edge means our Ingresses show up in their controller's config.

---

## 9. Upgrade / rollback / uninstall

```bash
helm upgrade  apim ./dist/apim-4.11.0.tgz -n $NS $KUBE -f helm/deploy/values-common.yaml -f helm/prod/values-prod.yaml [-f helm/prod/values-airgap.yaml]
helm history  apim -n $NS $KUBE
helm rollback apim <REVISION> -n $NS $KUBE
helm uninstall apim -n $NS $KUBE            # NOTE: PVCs are retained; delete explicitly if intended:
# helm uninstall obs -n $NS $KUBE           # the observability release (§5b), if deployed
# kubectl $KUBE -n $NS delete pvc --all     # ⚠️ destroys ES + Mongo data
```

---

## 10. Known limitations (accept or address)

- **Single-node data layer** — one ES node, 1-member Mongo RS. A node/disk loss loses that data
  unless restored from backup. This is the confirmed design; HA would need 3× members + anti-affinity.
- **One hostname for everything** — the gateway (`/`) shares `$HOST` with the admin console/API.
  For stronger zoning, split the gateway onto its own host (e.g. `api.$HOST`) and restrict the admin
  host. Also: any published API context-path under `/console`, `/management`, `/portal`, `/devportal`
  collides with the UI ingresses.
- **Gateway L7 only** — gRPC/TCP/mTLS-passthrough APIs can't traverse ingress-nginx. The fix is a
  dedicated `LoadBalancer` Service for the gateway, which needs a **spare IP from the platform's
  MetalLB pool** (§2(e)) — request one rather than adding a pool.
- **Observability paths share the APIM host** (§5b) — `/grafana`, `/prometheus` and `/kibana` sit on
  the same hostname and certificate as the Console, so Console reachability implies Grafana
  reachability. Split them onto an internal-only host if that is not acceptable. They also collide
  with any published API context-path of the same name, exactly like the UI paths above.
- **Shared edge** — the controller, its VIP and its cluster-wide ConfigMap belong to the platform.
  A platform-side change (class rename, policy flip, global `proxy-body-size`) can affect Gravitee
  without touching this repo. Re-run §2 after any platform maintenance.
```
