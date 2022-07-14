{{/*
Return the proper KONG image name
*/}}
{{- define "kong.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper kong migration image name
*/}}
{{- define "kong.migration.image" -}}
{{- if .Values.migration.image -}}
    {{- include "common.images.image" (dict "imageRoot" .Values.migration.image "global" .Values.global) -}}
{{- else -}}
    {{- template "kong.image" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "kong.imagePullSecrets" -}}
{{- if .Values.migration.image -}}
    {{- include "common.images.renderPullSecrets" (dict "images" (list .Values.image .Values.migration.image) "global" .Values.global) -}}
{{- else -}}
    {{- include "common.images.renderPullSecrets" (dict "images" (list .Values.image) "global" .Values.global) -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "kong.postgresql.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "postgresql" "chartValues" .Values.postgresql "context" $) -}}
{{- end -}}

{{/*
Get PostgreSQL host
*/}}
{{- define "kong.postgresql.host" -}}
{{- ternary (include "kong.postgresql.fullname" .) .Values.postgresql.external.host .Values.postgresql.enabled | quote -}}
{{- end -}}

{{/*
Get PostgreSQL port
*/}}
{{- define "kong.postgresql.port" -}}
{{- ternary "5432" .Values.postgresql.external.port .Values.postgresql.enabled | quote -}}
{{- end -}}

{{/*
Get PostgreSQL user
*/}}
{{- define "kong.postgresql.user" -}}
{{- if .Values.postgresql.enabled }}
    {{- if .Values.global.postgresql }}
        {{- if .Values.global.postgresql.auth }}
            {{- coalesce .Values.global.postgresql.auth.username .Values.postgresql.auth.username | quote -}}
        {{- else -}}
            {{- .Values.postgresql.auth.username | quote -}}
        {{- end -}}
    {{- else -}}
        {{- .Values.postgresql.auth.username | quote -}}
    {{- end -}}
{{- else -}}
    {{- .Values.postgresql.external.user | quote -}}
{{- end -}}
{{- end -}}

{{/*
Get PostgreSQL secret
*/}}
{{- define "kong.postgresql.secretName" -}}
{{- if .Values.postgresql.enabled }}
    {{- if .Values.global.postgresql }}
        {{- if .Values.global.postgresql.auth }}
            {{- if .Values.global.postgresql.auth.existingSecret }}
                {{- tpl .Values.global.postgresql.auth.existingSecret $ -}}
            {{- else -}}
               {{- default (include "kong.postgresql.fullname" .) (tpl .Values.postgresql.auth.existingSecret $) -}}
            {{- end -}}
        {{- else -}}
            {{- default (include "kong.postgresql.fullname" .) (tpl .Values.postgresql.auth.existingSecret $) -}}
        {{- end -}}
    {{- else -}}
        {{- default (include "kong.postgresql.fullname" .) (tpl .Values.postgresql.auth.existingSecret $) -}}
    {{- end -}}
{{- else -}}
    {{- default (printf "%s-external-secret" (include "common.names.fullname" .)) (tpl .Values.postgresql.external.existingSecret $) -}}
{{- end -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "kong.postgresql.databaseSecretKey" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print "password" -}}
{{- else -}}
    {{- if .Values.postgresql.external.existingSecret -}}
        {{- if .Values.postgresql.external.existingSecretPasswordKey -}}
            {{- printf "%s" .Values.postgresql.external.existingSecretPasswordKey -}}
        {{- else -}}
            {{- print "password" -}}
        {{- end -}}
    {{- else -}}
        {{- print "password" -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate values for kong.
*/}}
{{- define "kong.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "kong.validateValues.database" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}

{{/*
Function to validate the external database
*/}}
{{- define "kong.validateValues.database" -}}

{{- if not (eq .Values.database "postgres")  -}}
INVALID DATABASE: The value "{{ .Values.database }}" is not allowed for the "database" value. It must be "postgres".
{{- end }}

{{- if and (eq .Values.database "postgres") (not .Values.postgresql.enabled) (not .Values.postgresql.external.host) -}}
NO DATABASE: You disabled the PostgreSQL sub-chart but did not specify an external PostgreSQL host. Either deploy the PostgreSQL sub-chart by setting postgresql.enabled=true or set a value for postgresql.external.host.
{{- end }}

{{- if and (eq .Values.database "postgres") .Values.postgresql.enabled .Values.postgresql.external.host -}}
CONFLICT: You specified to deploy the PostgreSQL sub-chart and also specified an external
PostgreSQL instance. Only one of postgresql.enabled (deploy sub-chart) and postgresql.external.host can be set
{{- end }}

{{- end -}}