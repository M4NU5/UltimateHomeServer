# CLAUDE.md

Guidance for AI agents working in this repo. Read this first to skip rediscovery.

## What this repo is

A **Helm chart** (not a deployable app) that defines a self-hosted media stack (`*arr` + Jellyfin + supporting tools) running on **K3s**. The cluster lives on a separate VM and is reconciled by **ArgoCD** — this repo is the source of truth, you do not `helm install` or `kubectl apply` from here.

- `Chart.yaml` — Helm chart metadata (`name: Ultimate Home Server`, `version: 1.0.0`)
- `values.yaml` — single source of truth for what's enabled and how it's wired. Most edits land here.
- `values.example.yaml` — reference template
- `templates/` — one subdirectory per service (`deployment.yaml` + `service.yaml`)
- `templates/traefik/ingressroute/` — one IngressRoute YAML per externally-exposed service
- `apps/` — ArgoCD `Application` manifests (root-of-trust is `apps/root.yaml` → app-of-apps pattern)
- `sealed-secrets/`, `cert-manager/`, `reflector/` — supporting cluster infra

## Deployment flow (do not bypass)

You edit files → commit/push → ArgoCD on the cluster VM detects the change and syncs. **Do not run `helm install`, `kubectl apply`, or `helm upgrade` from this working directory** — it has no kubeconfig and isn't the cluster. `helm template` / `helm lint` are fine for local validation if helm is installed.

## The single pattern for adding a service

Every service follows the same four-file shape. Cloning an existing service is faster than reinventing.

1. **`templates/<svc>/deployment.yaml`** — Deployment, `replicas: {{ .Values.services.<svc>.replicaCount }}`, `strategy: Recreate`, label `app.kubernetes.io/name: <svc>`, gated by `{{- if .Values.services.<svc>.enabled }}`.
2. **`templates/<svc>/service.yaml`** — `ClusterIP` Service, port name `http`, `targetPort: http`, same enable gate.
3. **`templates/traefik/ingressroute/<svc>.yaml`** — one-liner:
   ```yaml
   {{- include "your-chart.ingressroute" (dict "name" "<svc>" "Values" .Values) }}
   ```
   This pulls in the helper at `templates/traefik/ingressroute/_common-ingress.tpl`, which auto-builds `https://<svc>.{{ .Values.services.traefik.domain }}` (currently `bongofett.com`), TLS via the shared `bongofett-cert`, with the `default-headers` middleware. Port comes from `services.<svc>.ports.http`.
4. **`values.yaml`** — add a block under `services:` with `enabled`, `replicaCount`, `image: { repository, tag, pullPolicy }`, `ports.http`, and `config` (hostPath). Add `data` and/or `seedbox` if the service needs library or downloads access.

**Best reference clones:**
- Stateless service with config only → copy `templates/changedetectionio/`
- Service that needs the media library → copy `templates/bazarr/` (mounts `/data` via PVC)
- Service that needs library + seedbox → copy `templates/sonarr/` or `templates/radarr/`
- Service with extra hostPath volumes (multiple persistence dirs, transcode cache, etc.) → copy `templates/tdarr/`

## Conventions you will be held to

**Env vars:** standard linuxserver-style `PUID=1000`, `PGID=1000`, `TZ` from `{{ .Values.common.tz }}`. Add `UMASK_SET=002` when the container will write to shared volumes.

**Storage paths inside containers:**
- `/config` — app config (hostPath on node)
- `/data` — media library (PVC `pvc-smb`, SMB-backed by `//192.168.0.2/NASty`)
- `/seedbox` — downloads (hostPath `/mnt/seedbox`, populated by `templates/seedbox/deployment.yaml` via rclone FUSE)
- Tdarr is the exception with `/media`, `/temp`, `/app/server`, `/app/configs`, `/app/logs` — it's still hostPath + PVC underneath, just multiple sub-paths.

**Storage paths on the K3s host:**
- `/var/lib/k3s/config/<svc>` — service config dirs (small, must persist)
- `/var/lib/k3s/cache/<svc>` — transient large caches (e.g., transcode temp). Keep these off the SMB PVC.
- `/mnt/seedbox` — rclone-mounted seedbox (read-write but treat seeding files as immutable; see safety note below)

**Service references in templates:**
- Namespace always `{{ .Values.common.namespace }}` (resolves to `home-server`).
- PVC claim name always `{{ .Values.storage.smb.pvcClaimName }}` (resolves to `pvc-smb`) — never hardcode.
- Domain always `{{ .Values.services.traefik.domain }}` — never hardcode `bongofett.com`.

**Disabling a service:** flip `services.<svc>.enabled: false` in `values.yaml`. The chart already gates every manifest on this; you don't need to delete files.

## Safety rules (these have caused outages)

1. **Never mount `/seedbox` into anything that re-encodes or modifies files.** Seeding torrents must keep their original bytes — re-encoding breaks hashes and earns HnR strikes on private trackers. Tdarr deliberately mounts only `/data`, never `/seedbox`.
2. **Never set `replicas > 1` for stateful services.** Most of the stack (Sonarr, Radarr, Jellyfin, Tdarr, qBittorrent, etc.) has SQLite databases or local state — two replicas will corrupt the DB. The `strategy: Recreate` everywhere is intentional, do not change to `RollingUpdate`.
3. **Don't commit raw secrets.** Secrets go through SealedSecrets — see `sealed-secrets/` and the `apps/sealed-*.yaml` manifests. The cert-manager email and SMB creds are already sealed; follow the same flow.
4. **Cert-manager is on the staging ACME endpoint** (`values.yaml:13`). Switching to prod is a deliberate one-line change; don't flip it incidentally.

## Hardware acceleration

Currently **none configured**. No `/dev/dri` device mounts, no `nvidia-device-plugin`, no `runtimeClassName: nvidia` anywhere. Jellyfin and Tdarr both transcode CPU-only today. If you're adding GPU support:
- Intel iGPU/QSV: add `volumeMounts` for `/dev/dri` + `securityContext.supplementalGroups: [44, 109]` (video, render).
- NVIDIA: needs the device-plugin DaemonSet installed cluster-side first, then `runtimeClassName: nvidia` + `resources.limits.nvidia.com/gpu: 1` on the pod.

## Currently enabled services (as of 2026-05)

`homepage`, `jellyfin`, `prowlarr`, `radarr`, `sonarr`, `bazarr`, `changedetectionio`, `playwright`, `tdarr`. Plus infra: `traefik`, `seedbox`, `smb`, `cert-manager`, `reflector`, `sealed-secrets`.

Disabled but configured (just flip `enabled: true`): `qbittorrent`, `sabnzbd`, `tautulli`, `overseerr`, `plex`, `apprise`, `autobrr`, `gotify`, `kavita`, `thelounge`, `huginn`, `cloudflared`, `unpackerr`, `caido`.

## Quick gotchas

- The Helm template helper is named `your-chart.ingressroute` (literally — it's a placeholder name that was never renamed). Don't "fix" it; every IngressRoute file references it.
- `homepage.bookmarks` and `homepage.services` in `values.yaml` are nested-list YAML and finicky — match the existing indentation exactly.
- The `sabnzbd` block in `values.yaml` is intentionally missing the full image/ports config; it's gated off by `enabled: false` and the disabled stub is fine. Don't pad it out unless enabling.
- `templates/traefik/ingressroute/_common-ingress.tpl` is the *only* template helper. There is no `_helpers.tpl` at chart root.

## Verification (without cluster access)

You can't `kubectl get` from this repo. To sanity-check changes:
- `helm lint .` — catches syntax/template errors
- `helm template . --debug | less` — renders the full output; grep for your service to confirm it appears with `enabled: true`
- Check the rendered IngressRoute: `helm template . | grep -A 20 "name: <svc>-ingress"`
- For real cluster verification, the user runs `kubectl` themselves from the cluster VM after ArgoCD syncs.
