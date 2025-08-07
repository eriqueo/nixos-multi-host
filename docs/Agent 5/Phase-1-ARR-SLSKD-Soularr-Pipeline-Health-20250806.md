# Phase 1 — ARR + SLSKD + Soularr Pipeline Health & Startup

**Agent 5: ARR Pipeline Automation & File Normalization Specialist**  
**Date:** 2025-08-06

---

## Executive Summary

This guide hardens your entire *arr + Soulseek pipeline:  
- Health and startup dependencies for Sonarr, Radarr, Lidarr, Prowlarr, SLSKD, Soularr, qBittorrent, SABnzbd  
- Clean startup, restart, and healthcheck order  
- NixOS-native systemd and testing practices  
- Includes rollback/runbook for operators

---

## Table of Contents

1. [Pipeline Overview & Dependency Map](#pipeline-overview--dependency-map)
2. [Systemd Service Ordering](#systemd-service-ordering)
3. [Healthcheck & Recovery Scripts](#healthcheck--recovery-scripts)
4. [Operator Runbook](#operator-runbook)
5. [Rollback & Testing](#rollback--testing)
6. [References](#references)

---

## Pipeline Overview & Dependency Map

```
media-network (systemd service)
│
├── gluetun (VPN gateway)
│   ├── qbittorrent (depends on gluetun)
│   └── sabnzbd (depends on gluetun)
│
├── *arr stack (independent)
│   ├── prowlarr
│   ├── sonarr
│   ├── radarr
│   └── lidarr
│
├── slskd (Soulseek client)
│   └── soularr (depends on slskd + lidarr)
│
└── navidrome (music streaming)
```
- **soularr** depends on both **slskd** and **lidarr**
- All downloaders should start *after* VPN/gateway is up

---

## Systemd Service Ordering

- Use `After=` and `Requires=` to control startup order for reliable pipeline boot:

```nix
systemd.services.podman-gluetun = {
  # ...existing config
  wantedBy = [ "media-network.target" ];
};
systemd.services.podman-qbittorrent = {
  requires = [ "podman-gluetun.service" ];
  after = [ "podman-gluetun.service" ];
};
systemd.services.podman-sabnzbd = {
  requires = [ "podman-gluetun.service" ];
  after = [ "podman-gluetun.service" ];
};
systemd.services.podman-slskd = {
  requires = [ "media-network.target" ];
  after = [ "media-network.target" ];
};
systemd.services.podman-soularr = {
  requires = [ "podman-slskd.service" "podman-lidarr.service" ];
  after = [ "podman-slskd.service" "podman-lidarr.service" ];
};
```

---

## Healthcheck & Recovery Scripts

- **Basic healthchecks**: Use `systemctl status` and container logs for all:
    ```bash
    sudo systemctl status podman-qbittorrent podman-sabnzbd podman-slskd podman-soularr podman-lidarr podman-sonarr podman-radarr podman-prowlarr
    sudo podman ps
    sudo podman logs slskd
    sudo podman logs soularr
    ```

- **Healthcheck command example** (for Soulseek/SLSKD):
    ```nix
    slskd = {
      # ...existing config
      healthcheck = {
        test = [ "CMD" "curl" "-f" "http://localhost:5030/health" ];
        interval = "30s";
        timeout = "10s";
        retries = 3;
      };
    };
    soularr = {
      healthcheck = {
        test = [ "CMD" "curl" "-f" "http://localhost:9898/health" ];
        interval = "30s";
        timeout = "10s";
        retries = 3;
      };
    };
    ```

---

## Operator Runbook

**If a pipeline component is DOWN:**
1. Check status and logs:
    ```bash
    sudo systemctl status podman-<servicename>
    sudo podman logs <servicename>
    ```
2. If *arr (Sonarr, Radarr, Lidarr, Prowlarr) is down:
    - Restart with: `sudo systemctl restart podman-<servicename>`
3. If SLSKD/Soularr is down:
    - Ensure Lidarr is up
    - Restart slskd, then soularr:
        ```bash
        sudo systemctl restart podman-slskd.service
        sudo systemctl restart podman-soularr.service
        ```
4. Confirm all containers with `sudo podman ps` and in ARR web UIs.

---

## Rollback & Testing

- All changes should be git-versioned:
    ```bash
    cd /etc/nixos
    git log --oneline
    sudo git checkout <previous-commit>
    sudo nixos-rebuild switch
    ```
- Always test full pipeline by simulating a restart of all services.
- Validate with real media downloads (torrents, usenet, soulseek) and check Lidarr/Soularr imports.

---

## References

- [Official SLSKD](https://github.com/slskd/slskd)
- [Soularr](https://github.com/advplyr/soularr)
- [NixOS systemd units](https://nixos.org/manual/nixos/stable/#sec-systemd-units)
- [ARR Apps Best Practices](https://wiki.servarr.com/)

---

*End of Phase 1 ARR + SLSKD + Soularr Pipeline Health & Startup*
