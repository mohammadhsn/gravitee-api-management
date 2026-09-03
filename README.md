

<div align="center">
  <a href="https://www.gravitee.io/">
    <picture>
      <source srcset="https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/refs/heads/master/assets/gravitee-dark-mode.svg" media="(prefers-color-scheme: dark)">
      <source srcset="https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/refs/heads/master/assets/gravitee-light-mode.svg" media="(prefers-color-scheme: light)">
      <img src="https://raw.githubusercontent.com/gravitee-io/gravitee-api-management/refs/heads/master/assets/gravitee-dark-mode.svg" alt="Gravitee Logo" style="max-width: 100%; height: auto;">
    </picture>
  </a>
</div>

<br/>

![Version][version-badge]
[![License][license-badge]][license-url]
[![LinkedIn][linkedin-badge]][linkedin-url]
[![Twitter][twitter-badge]][twitter-url]  
![Commit Activity][commit-activity-badge]
![Last Commit][last-commit-badge]
![CircleCI][circleci-badge]
[![Community][community-badge]][community-url]
[![Documentation][docs-badge]][docs-url]
---

<!-- ─────────────────────────── FORK SECTION ───────────────────────────
     Everything between these markers is specific to this fork. Upstream's
     README follows unchanged below. Kept in one contiguous block on purpose:
     an upstream merge then conflicts here and nowhere else.
     ──────────────────────────────────────────────────────────────────── -->

## About this fork

This is a fork of [gravitee-io/gravitee-api-management](https://github.com/gravitee-io/gravitee-api-management)
carrying our own deployment of APIM — Keycloak as the identity provider, a TLS
edge, observability, and a production bare-metal install. **Our documentation is
indexed in [`docs/README.md`](docs/README.md) — start there.**

### The big picture

APIM is four services over two datastores:

| Component | Port | Role |
| --- | --- | --- |
| **Gateway** | `8082` | The data plane. Proxies real API traffic and enforces policies (auth, rate limits, transforms). |
| **Management API** | `8083` | The control plane. Owns API definitions, plans, subscriptions and users; serves both UIs. |
| **Console UI** | `8084` | Admin interface — where APIs are designed, published and monitored. |
| **Portal UI** | `4100` | Developer portal — where consumers discover APIs and request access. |
| MongoDB | — | API definitions, subscriptions, users. The system of record. |
| Elasticsearch | — | Request analytics and logs. Written directly by the Gateway's reporter. |

**The one thing worth knowing up front:** the Gateway and the Management API
never call each other. The Management API writes to an *events* table, and each
Gateway polls it roughly every 5 seconds and reconfigures itself. So a change
made in the Console is not live until that sync happens, and if a deploy seems
not to take effect, that table is where to look. Treat it as the contract
between the two planes.

What this fork adds on top:

- **Keycloak** as the OIDC provider for console/portal login and for
  service-to-service tokens on proxied APIs.
- **A single TLS origin** — nginx (compose) or ingress-nginx (Kubernetes)
  terminating HTTPS and serving every component under one hostname, which is
  what keeps the browser's same-origin rules satisfied.
- **Observability** — Prometheus and Grafana for metrics, Kibana for request
  analytics and gateway logs, shipped by Filebeat and Logstash.
- **An air-gapped production install** on bare-metal Kubernetes, with every
  image mirrored to an internal registry and TLS from an internal CA.

### Where to run it

| If you want to… | Use |
| --- | --- |
| See the whole stack working locally | [`docker/quick-setup/keycloak/`](docker/quick-setup/keycloak/README.md) — the full demo on docker compose |
| Isolate one component | `cd docker && make help` — ~25 single-concern stacks (upstream's) |
| Rehearse a production change | [`helm/kind/`](helm/kind/) — a local cluster mirroring the prod topology |
| Deploy to production | [`helm/prod/DEPLOY-BAREMETAL.md`](helm/prod/DEPLOY-BAREMETAL.md) — the authoritative runbook |
| Run on a single VM, no Kubernetes | [`docs/nginx-setup/setup-guide.en.md`](docs/nginx-setup/setup-guide.en.md) |

Guides exist in English and Persian as hand-maintained pairs; see
[`docs/README.md`](docs/README.md) for the full list and for which documents are
ours versus upstream's.

<!-- ───────────────────────── END FORK SECTION ───────────────────────── -->

---

<span style="color:#ea3527"><strong>Gravitee API Management</strong></span> (also called <span style="color:#ea3527"><strong>Gravitee APIM</strong></span>)
is a flexible, lightweight, and blazing-fast Open Source solution that helps your organization control who, when, and how users access your APIs. \
Effortlessly manage the lifecycle of your APIs.

Download API Management to document, discover, and publish your APIs.

Different ways to start using <span style="color:#ea3527"><strong>Gravitee APIM</strong></span>:



| Tool                                                                                                                   | &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Target  &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
|------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Helm Chart][Helm-Chart-url]                                                                                           | <img src="https://raw.githubusercontent.com/kubernetes/kubernetes/refs/heads/master/logo/logo_with_border.svg" alt="Kubernetes Logo" height="35" style=" vertical-align:middle; margin-right:8px;"> <img src="https://az-icons.com/export/icons/d43291e40cdbc1574f9487f4370a746e.svg" alt="AKS Logo" height="35" style=" vertical-align:middle; margin-right:8px;"> <img src="https://www.gstatic.com/bricks/image/720ca2d9f0621d313fdc08f1d086a1638e65ea5fa08a0a18cf6eb58c8e974fd4.svg" alt="GKS Logo" height="35" style=" vertical-align:middle; margin-right:8px;"><img src="https://icon.icepanel.io/AWS/svg/Containers/EKS-Cloud.svg" alt="EKS Logo" height="35" style=" vertical-align:middle; margin-right:8px;"> <img src="https://upload.wikimedia.org/wikipedia/commons/3/3a/OpenShift-LogoType.svg" alt="Openshift Logo" height="35" style=" vertical-align:middle; margin-right:8px;"> |
| [docker-compose / make][quick-setup]                                                                                   | <img src="https://upload.wikimedia.org/wikipedia/commons/4/4e/Docker_%28container_engine%29_logo.svg" alt="Kubernetes Logo" height="20" style=" vertical-align:middle; margin-right:8px;">                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |

---
[Installation](https://documentation.gravitee.io/apim/getting-started/local-install-with-docker) | [Documentation](https://documentation.gravitee.io/apim) | [Community](https://community.gravitee.io/) | [Contributing](./CONTRIBUTING.adoc) | [License](./LICENSE.txt) | [Website][gravitee-url]

---


## Getting Started

To run <span style="color:#ea3527"><strong>Gravitee APIM</strong></span> on your own infrastructure with Docker, follow the steps below.

1) Clone the <span style="color:#ea3527"><strong>Gravitee APIM</strong></span> repository 
```sh
   git clone --depth=1 https://github.com/gravitee-io/gravitee-api-management
   cd gravitee-api-management/docker
```


2) Start the <a href="https://www.gravitee.io/platform/api-management" style="color:#ea3527; font-weight:bold;">Gravitee Console</a>, <a href="https://www.gravitee.io/platform/api-developer-portal" style="color:#ea3527; font-weight:bold;">Portal</a> and <a href="https://www.gravitee.io/platform/api-gateway" style="color:#ea3527; font-weight:bold;">Gateway</a> with a MongoDB database

 - Run the `Make` command

```sh
  make mongodb
```

- Or the `Docker` command
```sh
   cd quick-setup/mongodb && docker compose down -v && docker compose pull && docker compose up -d
```

3. <span style="color:#ea3527"><strong>Gravitee APIM</strong></span> is now up and running!<br>
   Let's explore some of the subcomponents you've deployed:

- `:4100` - [Portal UI](http://localhost:4100) ~ A catalog of your APIs, complete with documentation and more.
- `:8084` - [Console UI](http://localhost:8084) ~ The administrative interface for managing your APIs.
- `:8082` - Gateway ~ Gravitee's powerful API gateway.
- `:8083` - [APIM Backend](http://localhost:8083/portal/openapi) ~ Backend for both the Portal and Console UIs.  

Default credentials: `admin` / `admin`

\
What's next?
[Follow our documentation](https://documentation.gravitee.io/apim/how-to-guides) and learn how to create an API, add a Policy,... and more!

4.  💡 Tips (Optional)

>💡 Tip 1: Use your **Enterprise License**  
If you have an Enterprise License, you can export it as a Base64-encoded environment variable or move your license file into `docker/quick-setup/mongodb/.license` to gain full access to <span style="color:#ea3527"><strong>Gravitee APIM</strong></span> features.
 ```sh
    export LICENSE_KEY=*****
```

>💡 Tip 2: Issue when starting <span style="color:#ea3527"><strong>Gravitee APIM</strong></span>  
If you're having an issue during `.license` folder creation (using Rancher Desktop for example), please run:

```sh
   make prepare TARGET=mongodb
```

## Features

<div style="text-align: center;">
  <span style="
    background: linear-gradient(99deg, #f09135 2.8%, #ea3527 96.58%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    font-weight: bold;
    font-size: 24px;
  ">
    Hold Nothing Back!
  </span>
</div>

-   **Register your API**: Create and register APIs in a few clicks to easily expose your secured APIs to internal and external consumers.
-   **Configure policies using flows**: Gravitee.io API Management provides over 50 pre-built policies to effectively shape
    traffic reaching the gateway according to your business requirements.
-   **Developer portal**: Build the portal that your developers want with a custom theme, full-text search, and API documentation.
-   **Analytics dashboard**: The out-of-the-box dashboards give you a 360-degree view of your API. You can also build your own
    dashboards from Gravitee.io or use all metrics with external tools like Grafana or Kibana.
-   **Register applications**: Users and administrators can register applications for consuming APIs with ease. Gravitee.io
    provides advanced dynamic client registration to link API Management and Access Management effectively.
-   **Secured plans**: Create plans to define the rate limits, quotas, and security policies that apply to your APIs.

[![][gravitee-features]][gravitee-url]

[gravitee-url]: https://www.gravitee.io
[gravitee-features]: https://www.gravitee.io/hubfs/Spiralyze/assets/hero_1002.png
[quick-setup]: docker/README.md
[Helm-Chart-url]: https://documentation.gravitee.io/apim/hybrid-installation-and-configuration-guides/next-gen-cloud/kubernetes

[license-badge]: https://img.shields.io/github/license/gravitee-io/gravitee-api-management?style=flat&label=license&color=FF8A00
[license-url]: https://github.com/gravitee-io/gravitee-api-management/blob/master/LICENSE.txt

[linkedin-badge]: https://img.shields.io/badge/LinkedIn-Follow-blue?style=flat&color=22A3B3
[linkedin-url]: https://www.linkedin.com/company/gravitee-io

[twitter-badge]: https://img.shields.io/badge/Twitter-Follow-blue?style=flat&color=22A3B3
[twitter-url]: https://twitter.com/intent/follow?screen_name=graviteeio

[community-badge]: https://img.shields.io/badge/community-join-F76C6C?style=flat
[community-url]: https://community.gravitee.io

[docs-badge]: https://img.shields.io/badge/documentation-see-F76C6C?style=flat
[docs-url]: https://documentation.gravitee.io/apim

---

[version-badge]: https://img.shields.io/github/v/tag/gravitee-io/gravitee-api-management?style=flat&label=version&color=FF8A00
[commit-activity-badge]: https://img.shields.io/github/commit-activity/m/gravitee-io/gravitee-api-management?style=flat&color=F76C6C
[last-commit-badge]: https://img.shields.io/github/last-commit/gravitee-io/gravitee-api-management?style=flat&color=F76C6C
[circleci-badge]: https://img.shields.io/circleci/build/github/gravitee-io/gravitee-api-management?style=flat&color=F76C6C  