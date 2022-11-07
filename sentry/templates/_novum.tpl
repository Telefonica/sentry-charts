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
