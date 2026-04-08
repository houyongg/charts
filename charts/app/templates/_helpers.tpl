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
{{- $container := dict -}}
{{- if and (hasKey .Values "container") (kindIs "map" .Values.container) -}}
{{- $container = .Values.container -}}
{{- end -}}
{{- if and $container (hasKey $container "name") $container.name -}}
{{- $container.name -}}
{{- else -}}
{{- include "app.fullname" . -}}
{{- end -}}
{{- end }}

{{/*
envFrom helpers
*/}}
{{- define "app.envFrom" -}}
{{- $container := dict -}}
{{- if and (hasKey .Values "container") (kindIs "map" .Values.container) -}}
{{- $container = .Values.container -}}
{{- end -}}
{{- $items := list -}}
{{- $envConfigMap := dict -}}
{{- if and $container (hasKey $container "envConfigMap") (kindIs "map" $container.envConfigMap) -}}
{{- $envConfigMap = $container.envConfigMap -}}
{{- end -}}
{{- if and (hasKey $envConfigMap "enabled") $envConfigMap.enabled -}}
{{- $cmName := (default (printf "%s-env" (include "app.fullname" .)) $envConfigMap.name) -}}
{{- $items = append $items (dict "configMapRef" (dict "name" $cmName)) -}}
{{- end -}}
{{- $envSecret := dict -}}
{{- if and $container (hasKey $container "envSecret") (kindIs "map" $container.envSecret) -}}
{{- $envSecret = $container.envSecret -}}
{{- end -}}
{{- if and (hasKey $envSecret "enabled") $envSecret.enabled -}}
{{- $secName := (default (printf "%s-env" (include "app.fullname" .)) $envSecret.name) -}}
{{- $items = append $items (dict "secretRef" (dict "name" $secName)) -}}
{{- end -}}
{{- $extraEnvFrom := list -}}
{{- if and $container (hasKey $container "envFrom") (kindIs "slice" $container.envFrom) -}}
{{- $extraEnvFrom = $container.envFrom -}}
{{- end -}}
{{- range $extraEnvFrom -}}
{{- $items = append $items . -}}
{{- end -}}
{{- if gt (len $items) 0 -}}
{{- toYaml $items -}}
{{- end -}}
{{- end }}
