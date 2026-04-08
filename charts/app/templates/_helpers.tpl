{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Container name
*/}}
{{- define "app.containerName" -}}
{{- if .Values.container.name -}}
{{- .Values.container.name -}}
{{- else -}}
{{- include "app.fullname" . -}}
{{- end -}}
{{- end }}

{{/*
envFrom helpers
*/}}
{{- define "app.envFrom" -}}
{{- $items := list -}}
{{- if .Values.container.envConfigMap.enabled -}}
{{- $cmName := (default (printf "%s-env" (include "app.fullname" .)) .Values.container.envConfigMap.name) -}}
{{- $items = append $items (dict "configMapRef" (dict "name" $cmName)) -}}
{{- end -}}
{{- if .Values.container.envSecret.enabled -}}
{{- $secName := (default (printf "%s-env" (include "app.fullname" .)) .Values.container.envSecret.name) -}}
{{- $items = append $items (dict "secretRef" (dict "name" $secName)) -}}
{{- end -}}
{{- range .Values.container.envFrom -}}
{{- $items = append $items . -}}
{{- end -}}
{{- if gt (len $items) 0 -}}
{{- toYaml $items -}}
{{- end -}}
{{- end }}
