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
envConfigMap / envSecret 为键值 map：非空则创建资源名 <fullname>-env 并 envFrom 挂载（ConfigMap 与 Secret 为不同 kind，可同名）。
*/}}
{{- define "app.envConfigMapMountName" -}}
{{- $root := . -}}
{{- $container := dict -}}
{{- if and (hasKey .Values "container") (kindIs "map" .Values.container) -}}
{{- $container = .Values.container -}}
{{- end -}}
{{- $envConfigMap := dict -}}
{{- if and $container (hasKey $container "envConfigMap") (kindIs "map" $container.envConfigMap) -}}
{{- $envConfigMap = $container.envConfigMap -}}
{{- end -}}
{{- if gt (len $envConfigMap) 0 -}}
{{- printf "%s-env" (include "app.fullname" $root) -}}
{{- end -}}
{{- end }}

{{- define "app.envSecretMountName" -}}
{{- $root := . -}}
{{- $container := dict -}}
{{- if and (hasKey .Values "container") (kindIs "map" .Values.container) -}}
{{- $container = .Values.container -}}
{{- end -}}
{{- $envSecret := dict -}}
{{- if and $container (hasKey $container "envSecret") (kindIs "map" $container.envSecret) -}}
{{- $envSecret = $container.envSecret -}}
{{- end -}}
{{- if gt (len $envSecret) 0 -}}
{{- printf "%s-env" (include "app.fullname" $root) -}}
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
{{- $cmName := include "app.envConfigMapMountName" . | trim -}}
{{- if $cmName -}}
{{- $items = append $items (dict "configMapRef" (dict "name" $cmName)) -}}
{{- end -}}
{{- $secName := include "app.envSecretMountName" . | trim -}}
{{- if $secName -}}
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
