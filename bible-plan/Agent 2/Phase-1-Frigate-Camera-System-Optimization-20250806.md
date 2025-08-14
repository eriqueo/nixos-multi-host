# Phase 1 — Frigate & Camera System Optimization

**Agent 2: Surveillance/Frigate Optimization Agent**  
**Date:** 2025-08-06

---

## Executive Summary

This phase delivers a NixOS-native, research-driven playbook for:
- Frigate 0.13+ deployment on NVIDIA Quadro P1000 (Pascal, TensorRT)
- Camera reliability/network best practices
- Motion masking, detection zones, object filtering to reduce false positives
- **Automated, storage-capped (≤2TB) retention**: combine Frigate built-in + external systemd pruning
- Full-stack monitoring, event alerting, and rollback

---

## Table of Contents

1. [P1000 + Frigate Detection Pipeline Optimization](#p1000--frigate-detection-pipeline-optimization)
2. [Camera Reliability and Network Hardening](#camera-reliability-and-network-hardening)
3. [Motion Masking, Zones, and Object Filters](#motion-masking-zones-and-object-filters)
4. [Automated Recording Retention & Storage Pruning (2TB cap)](#automated-recording-retention--storage-pruning-2tb-cap)
5. [Monitoring, Alerting, and Integration](#monitoring-alerting-and-integration)
6. [Testing, Validation, and Rollback](#testing-validation-and-rollback)
7. [References](#references)

---

## P1000 + Frigate Detection Pipeline Optimization

### Hardware/Driver/TensorRT Tips

- **Driver:** Use NVIDIA proprietary, >= 470 for stable NVENC/NVDEC, >= 510 recommended.
- **TensorRT:** Pascal cards (P1000) are supported; set `USE_FP16 = "false"` for Frigate’s object detection.
- **CUDA compute:** 6.1 (limit parallel inferencing if VRAM saturates).
- **VRAM:** 4GB is usually sufficient for 2-4 4K or 1080p streams at moderate detection sizes (recommend 640x480 to 1280x720 for detection).

### Frigate Container Example (NixOS, Podman)

```nix
frigate = {
  image = "blakeblackshear/frigate:stable";
  autoStart = true;
  extraOptions = [
    "--gpus=all"
    "--device=/dev/nvidia0:/dev/nvidia0"
    "--device=/dev/nvidiactl:/dev/nvidiactl"
    "--device=/dev/nvidia-modeset:/dev/nvidia-modeset"
    "--device=/dev/nvidia-uvm:/dev/nvidia-uvm"
    "--device=/dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools"
    "--shm-size=1g"
    "--network=host"
  ];
  environment = {
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "compute,utility,video";
    FRIGATE_RTSP_PASSWORD = "yourpassword";
    USE_FP16 = "false";
  };
  volumes = [
    "/mnt/hot/surveillance:/media"
    "/etc/localtime:/etc/localtime:ro"
    # add your config path
  ];
  ports = [ "5000:5000" ];
};
```

### Frigate Config (Detection block, TensorRT)

```yaml
detectors:
  tensorrt:
    type: tensorrt
    device: 0
    model:
      path: /models/yolov8n-640.trt
      input_width: 640
      input_height: 640
      labelmap_path: /models/coco-labels-paper.txt
      fp16: false # For Pascal, use FP32
    num_threads: 2 # More threads = faster, but can OOM VRAM; test 2-4 for P1000
```

---

## Camera Reliability and Network Hardening

- **Use static IPs** for all cameras (avoid IP collision).
- **Isolate surveillance VLAN or subnet** (protect from broadcast/multicast storms).
- **Use RTSP over TCP** for most reliable video (UDP can drop frames).
- **Set RTSP keepalive:** Frigate: `rtsp_transport: tcp`, increase `rtsp_timeout` in Frigate input config.
- **Physical:** Check power injectors/PoE, weatherproof connections.

Example input block:
```yaml
cameras:
  cobra_cam_1:
    ffmpeg:
      inputs:
        - path: "rtsp://admin:password@192.168.1.101:554/ch01/0"
          roles: [ detect, record ]
          global_args: [ "-rtsp_transport", "tcp", "-timeout", "30000000" ]
```

---

## Motion Masking, Zones, and Object Filters

### Masks

- **Purpose:** Hide time overlays, trees, passing cars, etc. from detection.
- **Syntax:** List of polygon coordinates or rectangles.

```yaml
motion:
  mask:
    - "0,0,1920,0,1920,60,0,60"        # Mask top overlay
    - "0,1000,200,1080,0,1080"         # Mask bottom-left
    - "1720,1000,1920,1080,1920,1080"  # Mask bottom-right
```

### Detection Zones

- **Purpose:** Alert only if object crosses into a region.
```yaml
zones:
  driveway:
    coordinates: "500,800,1420,800,1420,1080,500,1080"
    objects: [ "person", "car" ]
```

### Object Filters

```yaml
objects:
  filters:
    person:
      min_area: 3500
      max_area: 80000
      threshold: 0.75
    car:
      min_area: 12000
      threshold: 0.7
```

---

## Automated Recording Retention & Storage Pruning (2TB cap)

### **1. Frigate’s Built-in Retention**

In `frigate.yml` (per camera or global):

```yaml
record:
  enabled: true
  retain:
    days: 10          # Default; adjust for your typical usage
    mode: "motion"
  events:
    retain:
      default: 30     # Keep events longer, if desired
      mode: "active_objects"
```
- This keeps files for X days. But: *does not guarantee a hard cap in GB/TB.*

---

### **2. NixOS-native Absolute Storage Cap with Systemd/Bash**

**Goal:** Always keep `/mnt/hot/surveillance` under 2TB, pruning oldest video/event folders first.

#### **systemd Service**

```nix
systemd.services.frigate-storage-prune = {
  description = "Self-prune Frigate recordings to keep under 2TB";
  startAt = "hourly";
  script = ''
    DIR="/mnt/hot/surveillance"
    MAX_BYTES=$((2*1024*1024*1024*1024)) # 2TB

    while [ "$(du -sb "$DIR" | awk '{print $1}')" -gt "$MAX_BYTES" ]; do
      # Find oldest recording folder (events or recordings)
      TARGET=$(find "$DIR" -type d -name "[0-9]*" -printf "%T@ %p
" | sort -n | head -n1 | cut -d' ' -f2-)
      if [ -z "$TARGET" ]; then
        echo "Nothing left to prune, but over cap!"
        break
      fi
      echo "Deleting $TARGET to reduce usage"
      rm -rf "$TARGET"
    done
  '';
};
```

**- This script prunes oldest date-stamped folders (the default in Frigate’s storage structure) until usage is <2TB.**  
**- Test by running manually and checking with `du -h /mnt/hot/surveillance`.**

---

### **3. Option: Hard cap for *only* recordings or events**

Adjust the `find ...` glob in the script to target e.g. `/mnt/hot/surveillance/recordings/*`  
or `/mnt/hot/surveillance/events/*` for finer control.

---

## Monitoring, Alerting, and Integration

- **Prometheus scraping:** Use Frigate’s `/api/stats` for live detection, recording, and GPU metrics.
- **Alerting:** Add Prometheus rules for dropped cameras, high GPU utilization, failed prunes (script errors).
- **Business Metrics Integration:**  
  Optionally, POST motion or event triggers from Frigate to your business dashboard or notification system.

---

## Testing, Validation, and Rollback

### Testing

- **Test config with**:
    ```bash
    sudo nixos-rebuild test --flake .#$(hostname)
    sudo podman logs frigate
    ```
- **Check GPU utilization:**  
    `watch -n 1 nvidia-smi`
- **Test storage pruning:**
    ```bash
    sudo systemctl start frigate-storage-prune.service
    du -h /mnt/hot/surveillance
    ```
- **Check logs for errors or over-pruning.**

### Rollback

- All configs should be git versioned.  
    - To undo:
        ```bash
        sudo git checkout <previous-commit>
        sudo nixos-rebuild switch
        ```
    - Or, to restore backup config:
        ```bash
        sudo cp /etc/nixos/hosts/server/modules/surveillance.nix.backup /etc/nixos/hosts/server/modules/surveillance.nix
        sudo nixos-rebuild switch
        ```

---

## References

- [Frigate GPU/TensorRT](https://docs.frigate.video/hardware/video_acceleration#nvidia)
- [NVIDIA P1000 Product Specs](https://www.nvidia.com/en-us/data-center/quadro-p1000/)
- [Frigate Retention](https://docs.frigate.video/configuration/record/#retention)
- [Frigate Motion Masks/Zones](https://docs.frigate.video/configuration/camera/#zones)
- [NixOS Systemd services](https://nixos.org/manual/nixos/stable/#sec-systemd-units)
- [Prometheus/Grafana Integration](https://docs.frigate.video/integrations/prometheus/)

---

*End of Phase 1 Frigate & Camera System Optimization*
