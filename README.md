
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

The Web UI has no public ingress. After deployment, forward it through the cluster VM with `ssh -L 8080:127.0.0.1:8080 k3s@192.168.1.5 'kubectl -n home-server port-forward --address 127.0.0.1 svc/qbittorrent 8080:8080'`, then open `http://localhost:8080`. Get the temporary `admin` password from `ssh k3s@192.168.1.5 'kubectl -n home-server logs deploy/qbittorrent -c qbittorrent'` and set a permanent password in the Web UI. The initial download and ratio settings are written only when the config file is absent; subsequent Web UI changes persist.

### Network
- 🌐 [`traefik`](https://doc.traefik.io/): A kubernetes native high-performance web server and reverse proxy.
- ☁️ [`cloudflared`](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/): Expose services running on your home network to the internet.
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
