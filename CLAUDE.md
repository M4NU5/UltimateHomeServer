# CLAUDE.md

A **Helm chart** defining a self-hosted media stack (`*arr` + Jellyfin + tools) on **K3s**.

## Deployment flow

Edit → commit → push. ArgoCD on the cluster VM reconciles from git. This repo is the
source of truth; there is no kubeconfig here. Don't `helm install`/`upgrade` or
`kubectl apply` from this directory. `helm lint .` and `helm template .` are the local checks.

Cluster VM (read-only debugging is fine, e.g. `kubectl get`/`logs`/`describe`):
`ssh k3s@192.168.0.5`

## Layout

- `values.yaml` — what's enabled and how it's wired. Most edits land here.
- `templates/<svc>/` — `deployment.yaml` + `service.yaml` per service
- `templates/traefik/ingressroute/<svc>.yaml` — one per exposed service
- `apps/` — ArgoCD `Application` manifests (`apps/root.yaml` is the app-of-apps root)

## Adding a service

Clone an existing one. Four files: deployment, service, ingressroute, plus a `values.yaml`
block with `enabled`, `replicaCount`, `image`, `ports.http`, `config`. Gate every manifest
on `{{- if .Values.services.<svc>.enabled }}`.

The ingressroute is a one-liner that auto-builds `https://<svc>.<domain>` with TLS and the
`default-headers` middleware:

```yaml
{{- include "your-chart.ingressroute" (dict "name" "<svc>" "Values" .Values) }}
```

Its helper lives in `templates/traefik/ingressroute/_common-ingress.tpl` — the only template
helper in the chart. The name `your-chart` is a placeholder that was never renamed; every
IngressRoute references it, so don't "fix" it.

## Conventions

Env: `PUID=1000`, `PGID=1000`, `TZ` from `.Values.common.tz`. Add `UMASK_SET=002` when the
container writes to shared volumes.

Container paths: `/config` (app config, hostPath), `/data` (media library, PVC), `/seedbox`
(downloads, hostPath). Tdarr is the exception — it uses `/media`, `/temp`, `/app/*`.

Host paths: `/var/lib/k3s/config/<svc>` for config, `/var/lib/k3s/cache/<svc>` for large
transient caches (keep these off the SMB PVC), `/mnt/seedbox` for the rclone mount.

Never hardcode: use `.Values.common.namespace`, `.Values.storage.smb.pvcClaimName`, and
`.Values.services.traefik.domain`.

## Safety rules (these have caused outages)

1. **Never mount `/seedbox` into anything that re-encodes files.** Seeding torrents must keep
   their original bytes or you get HnR strikes. Tdarr mounts only `/data`.
2. **Never set `replicas > 1`.** Most services hold SQLite state; two replicas corrupt the DB.
   The `strategy: Recreate` everywhere is deliberate.
3. **No raw secrets.** Everything goes through SealedSecrets — see `sealed-secrets/`.
4. **cert-manager is on the staging ACME endpoint.** Switching to prod is a deliberate change.

## Homepage config

`values.yaml` feeds `templates/homepage/configmap.yaml` verbatim via `toYaml`. The nesting is
**not** uniform and getting it wrong silently drops every property, leaving bare unlinked
tiles. Check the format against <https://gethomepage.dev/configs/> rather than copying the
surrounding style:

- `services` → group → name → a **map** (`icon`, `href`, `ping`, `widget` as keys)
- `bookmarks` → group → name → a **list holding one map** (`abbr`, `href`, `icon` together)

Verify a change actually parsed, rather than trusting that it rendered:

```bash
ssh k3s@192.168.0.5 'kubectl -n home-server exec deploy/homepage -c homepage -- \
  wget -qO- http://localhost:3000/api/services'
```

Numeric `"0"`, `"1"` keys in that output mean the nesting is wrong.

Widget API keys come from an optional `homepage-secrets` secret as `HOMEPAGE_VAR_*`. Without
it the tiles and ping dots still work; only the stat blocks are empty.
