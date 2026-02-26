{{- define "your-chart.ingressroute" }}
{{- $name := .name }}
{{- $svc := index .Values.services $name }}
{{- if $svc.enabled }}
{{- $domain := printf "%s.%s" $name $.Values.services.traefik.domain }}
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: {{ $name }}-ingress
  namespace: {{ .Values.common.namespace }}
  labels:
    app.kubernetes.io/name: {{ $name }}
spec:
  entryPoints:
    - websecure
  routes:
    - kind: Rule
      match: Host(`{{ $domain }}`)
      services:
        - kind: Service
          name: {{ $name }}
          port: {{ $svc.ports.http }}
      middlewares:
        - name: default-headers
  tls:
    secretName: bongofett-cert
{{- end }}
{{- end }}
