{{- define "tb.fullname" -}}
{{- printf "%s-%s" .Release.Name (.Chart.Name | replace "gravitee-" "") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "tb.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: gravitee-apim
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/* Same air-gap lever as the observability chart: one global repoints the image. */}}
{{- define "tb.image" -}}
{{- $reg := .ctx.Values.global.imageRegistry | default "" -}}
{{- if $reg -}}
{{ printf "%s/%s" $reg .image }}
{{- else -}}
{{ .image }}
{{- end -}}
{{- end -}}
