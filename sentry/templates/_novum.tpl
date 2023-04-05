{{/* vim: set filetype=mustache: */}}

{{/*
Check if secret is needed for clickhouse
*/}}
{{- define "novum.sentry.clickhouse.createSecret" -}}
{{- if .Values.clickhouse.enabled -}}
    {{- if .Values.clickhouse.clickhouse.configmap.users.enabled -}}
      {{- true -}}
    {{- end -}}
{{- else -}}
    {{- if ne .Values.externalClickhouse.password "" -}}
      {{- true -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Use snuba-env from ConfigMap or Secret
*/}}
{{- define "novum.sentry.snuba.envFrom" -}}
{{- if (include "novum.sentry.clickhouse.createSecret" .) }}
- secretRef:
{{- else }}
- configMapRef:
{{- end }}
    name: {{ template "sentry.fullname" . }}-snuba-env
{{- end -}}

{{/*
Add additional Novum environment variables
*/}}
{{- define "novum.sentry.env" -}}
{{- /* NOVUM: Add fixed REDIS_PORT to avoid k8s injecting an automatic REDIS_PORT variable for the service REDIS */}}
- name: REDIS_PORT
  value: "6379"
{{- if .Values.novum.statsiteProxy.enabled }}
- name: SENTRY_STATSITE_PROXY
  value: "{{ include "sentry.fullname" .}}-statsite-proxy-novum"
{{- end }}
{{- end -}}

{{/*
Add additional Novum environment variables for Snuba containers
*/}}
{{- define "novum.snuba.env" -}}
{{ include "novum.sentry.env" . }}
{{- end -}}
