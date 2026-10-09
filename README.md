
<p align="center">
  <img src=".github/img/header.png" alt="Banner" width="100%">
</p>

<p align="center">
  <!-- Add shields from https://shields.io/ -->
  <a href="https://github.com/sponsors/M4NU5">
    <img alt="GitHub Sponsors" src="https://img.shields.io/github/sponsors/M4NU5">
  </a>
  <img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/TechSquidTV/UltimateHomeServer/commitlint.yml">
</p>


<p align="center">
  <a href="https://ultimatehomeserver.com/"> UltimateHomeServer.com</a>
</p>

<p align="center">
  Deploy the ultimate home server stack with <a href="https://k3s.io/"> K3s </a> and <a href="https://helm.sh/">Helm</a>.
  Created by [KyleTryon](https://github.com/KyleTryon)
  Perfected by [M4NU5](https://github.com/M4NU5)
</p>


## Getting Started

Here are some useful resources to get you started:
- [TRasSH-Guides](https://trash-guides.info/)
- [ultimatehomeserver](https://www.ultimatehomeserver.com/docs/)

---

## Services
### Dashboard
- 🏠 [`homepage`](https://gethomepage.dev/): A customizable start page for your home server.
### Media
- 🪼 [`jellyfin`](https://jellyfin.org/): The free software media system. (Recommended)
- 📺 [`plex`](https://www.plex.tv/): A personal media server. (Not advised, Plex was not designed to container environments like this)
- 📖 [`kavita`](https://www.kavitareader.com/): A modern reading server for manga, comics, and books.
### Media Management
- ⏺️ [`sonarr`](https://sonarr.tv/): An automated TV show download and management system.
- 🎬 [`radarr`](https://radarr.video/): An automated movie download and management system.
- 🐯 [`prowlarr`](https://github.com/Prowlarr/Prowlarr): Manage indexers for your *arr stack.
- [`bazarr`](https://www.bazarr.media/): Automated subtitles for sonarr & radarr.
- 👁️ [`overseerr`](https://overseerr.dev/): A request management and media discovery tool.
- 📊 [`tautulli`](https://tautulli.com/): Monitor your Plex Media Server.
- 🐇 [`autobrr`](https://autobrr.com/): Automatically search and download from IRC.
### Download
- ⏬ [`qbittorrent`](https://www.qbittorrent.org/): A lightweight and feature-rich torrent client.
- 📰 [`sabnzbd`](https://sabnzbd.org/): The automated Usenet download tool.

The in-cluster qBittorrent is for manually selected torrents with no seeding obligation. It uses its own config at `/var/lib/k3s/config/qbittorrent-local` and saves to `/data/downloads/qbittorrent` on the media PVC; it does not use `/mnt/seedbox`. New installs stop torrents when they reach a share ratio of zero. Peers can still receive uploaded pieces while a download is in progress, so do not use it for torrents with seeding requirements.

The Web UI is available at [qbittorrent.bongofett.com](https://qbittorrent.bongofett.com). Get the temporary `admin` password from `ssh k3s@192.168.1.5 'kubectl -n home-server logs deploy/qbittorrent -c qbittorrent'` and set a permanent password in the Web UI promptly. If the HTTPS route is unavailable, forward the service through the cluster VM with `ssh -L 8080:127.0.0.1:8080 k3s@192.168.1.5 'kubectl -n home-server port-forward --address 127.0.0.1 svc/qbittorrent 8080:8080'`, then open `http://localhost:8080`. The initial download and ratio settings are written only when the config file is absent; subsequent Web UI changes persist.

### Network
- 🌐 [`traefik`](https://doc.traefik.io/): A kubernetes native high-performance web server and reverse proxy.
- ☁️ [`cloudflared`](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/): Expose services running on your home network to the internet.

Connect to Tailscale to use [Homepage](https://homepage.bongofett.com), [Jellyfin](https://jellyfin.bongofett.com), and [ArgoCD](https://argocd.bongofett.com) away from home. All three names resolve to `192.168.1.5`; `k3s-master` already advertises the approved `192.168.1.5/32` subnet route, which carries HTTPS traffic to the existing Traefik ingress. The same links work on the home LAN. No exit node or public port forwarding is required.

[Windows, macOS, and mobile clients accept subnet routes automatically](https://tailscale.com/docs/features/subnet-routers#use-your-subnet-routes-from-other-devices). On a Linux client, enable them with `sudo tailscale set --accept-routes=true`. Tailscale access rules must permit the client to reach `192.168.1.5:443`. Keep the host route narrow: it covers the cluster's HTTPS services and Homepage links to them, but does not provide remote access to the router (`192.168.1.1`).

In Jellyfin's **Dashboard → Networking → Local networks**, use `192.168.1.0/24,10.42.0.0/24,100.64.0.0/10`. The Tailscale range is needed because Traefik forwards the client's Tailscale IP. Keep **Allow remote connections to this server** disabled and retain the existing known proxy range (`10.42.0.0/24`). These settings persist in `/var/lib/k3s/config/jellyfin/network.xml`, outside the Helm release. Save and restart Jellyfin after changing them. Before editing this file directly, stop the Jellyfin process and back up the file; restore that backup while the process is stopped to roll back.

From a client connected to Tailscale, check the existing HTTPS routes:

```bash
curl --fail --silent --show-error https://jellyfin.bongofett.com/System/Info/Public
curl --fail --silent --show-error --output /dev/null https://homepage.bongofett.com
curl --fail --silent --show-error --output /dev/null https://argocd.bongofett.com
tailscale ping k3s-master
```

The HTTP checks confirm app access, and `tailscale ping` reports a direct or relayed tunnel. Verify playback separately; these checks do not measure streaming throughput. For a remote check, repeat them on a hotspot or another network.

### Messaging
- 💬 [`thelounge`](https://thelounge.chat/): A modern, self-hosted web IRC client.
### Notifications
- 📲 [`gotify`](https://gotify.net/docs/plugin): Self-hosted push notifications.
- 📲 [`apprise`](https://github.com/caronc/apprise-api): Multi-platform push notifications.
### Automation
- 🦅 [`huginn`](https://github.com/huginn/huginn): Create agents that monitor and act on your behalf.
- 🔄 [`changedetection.io`](https://changedetection.io): Monitor web pages for changes.
### Development
- 🎭 [`playwright`](https://playwright.dev/): A headless browser automator.

---

## CLI

View the [`uhs-cli` repository](https://github.com/TechSquidTV/uhs-cli) for more information.

---

## Thanks
<p align="center">
  Made with ❤️, built on the backs of <a href="https://wiki.servarr.com/">*arr stack</a>, <a href="https://www.linuxserver.io/"> linuxserver.io</a>, and more awesome open-source projects.
</p>
