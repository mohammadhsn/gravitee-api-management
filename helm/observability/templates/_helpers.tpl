{{/* Common name / labels helpers */}}
{{- define "obs.fullname" -}}
{{- printf "%s-%s" .Release.Name (.Chart.Name | replace "gravitee-" "") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "obs.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: gravitee-apim
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/*
Shared ingress boilerplate. Call with a dict: (dict "ctx" $ "name" "prometheus"
"path" "/prometheus" "svc" "obs-prometheus" "port" 9090).
Path is ImplementationSpecific with a rewrite so the backend sees the sub-path it was
told to serve (each app is also configured with its own root-url/basepath, so the
prefix is preserved rather than stripped).
*/}}
{{- define "obs.ingress" -}}
{{- $ctx := .ctx -}}
{{- if $ctx.Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .svc }}
  labels:
    {{- include "obs.labels" $ctx | nindent 4 }}
  {{- with $ctx.Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  ingressClassName: {{ $ctx.Values.ingress.ingressClassName }}
  {{- if $ctx.Values.ingress.tls.enabled }}
  tls:
    - hosts:
        - {{ $ctx.Values.ingress.host | quote }}
      secretName: {{ $ctx.Values.ingress.tls.secretName }}
  {{- end }}
  rules:
    - host: {{ $ctx.Values.ingress.host | quote }}
      http:
        paths:
          - path: {{ .path }}
            pathType: Prefix
            backend:
              service:
                name: {{ .svc }}
                port:
                  number: {{ .port }}
{{- end -}}
{{- end -}}

{{/*
Image reference with optional internal-registry prefix.
Air-gapped clusters set global.imageRegistry once and every image below is repointed —
the same lever helm/prod/values-airgap.yaml pulls for the Bitnami subcharts.
Usage: {{ include "obs.image" (dict "ctx" $ "image" .Values.grafana.image) }}
*/}}
{{- define "obs.image" -}}
{{- $reg := .ctx.Values.global.imageRegistry | default "" -}}
{{- if $reg -}}
{{ printf "%s/%s" $reg .image }}
{{- else -}}
{{ .image }}
{{- end -}}
{{- end -}}
