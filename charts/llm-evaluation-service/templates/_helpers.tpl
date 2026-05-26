{{- define "llm-evaluation-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "llm-evaluation-service.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "llm-evaluation-service.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "llm-evaluation-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "llm-evaluation-service.baseSelectorLabels" -}}
app.kubernetes.io/name: {{ include "llm-evaluation-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "llm-evaluation-service.selectorLabels" -}}
{{- include "llm-evaluation-service.baseSelectorLabels" . }}
app.kubernetes.io/component: service
{{- end -}}

{{- define "llm-evaluation-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- include "llm-evaluation-service.fullname" . -}}
{{- else -}}
default
{{- end -}}
{{- end -}}

{{- define "llm-evaluation-service.secretName" -}}
{{- if .Values.secrets.existingSecretName -}}
{{- .Values.secrets.existingSecretName -}}
{{- else -}}
{{- printf "%s-secrets" (include "llm-evaluation-service.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "llm-evaluation-service.postgresName" -}}
{{- printf "%s-postgres" (include "llm-evaluation-service.fullname" .) -}}
{{- end -}}

{{- define "llm-evaluation-service.consoleName" -}}
{{- printf "%s-console" (include "llm-evaluation-service.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "llm-evaluation-service.consoleSelectorLabels" -}}
app.kubernetes.io/name: {{ include "llm-evaluation-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: console
{{- end -}}

{{- define "llm-evaluation-service.workerName" -}}
{{- printf "%s-worker" (include "llm-evaluation-service.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "llm-evaluation-service.workerSelectorLabels" -}}
app.kubernetes.io/name: {{ include "llm-evaluation-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: worker
{{- end -}}

{{- define "llm-evaluation-service.serviceUrl" -}}
{{- printf "http://%s:%d" (include "llm-evaluation-service.fullname" .) (.Values.service.port | int) -}}
{{- end -}}
