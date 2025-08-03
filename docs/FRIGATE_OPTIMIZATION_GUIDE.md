# Frigate Camera System Optimization Guide

## 📋 Current Status Assessment

### ✅ Working Components
- **Hardware**: NVIDIA Quadro P1000 with TensorRT optimization
- **Storage**: Two-tier architecture (SSD hot storage + HDD cold storage)
- **Container**: Properly configured with GPU acceleration
- **MQTT**: Mosquitto broker running for event communication

### 🔴 Critical Issues Requiring Immediate Attention

#### 1. Configuration Validation Error (BLOCKING)
**Error**: `cameras.cobra_cam_1.ffmpeg.inputs: Value error, Each input role may only be used once.`

**Problem Location**: `/etc/nixos/hosts/server/modules/surveillance.nix` around lines 180-200

**Fix Required**:
```yaml
# CURRENT BROKEN CONFIG:
inputs:
  - path: rtsp://admin:password@192.168.1.100/stream1
    roles: [ detect, record ]  # ❌ PROBLEM: record role used twice
  - path: rtsp://admin:password@192.168.1.100/stream2  
    roles: [ record ]          # ❌ PROBLEM: record role duplicate

# CORRECTED CONFIG:
inputs:
  - path: rtsp://admin:password@192.168.1.100/stream1
    roles: [ detect, record ]
  - path: rtsp://admin:password@192.168.1.100/stream2
    roles: [ audio ]  # OR remove this input entirely
```

#### 2. Camera Status Issues
- **cobra_cam_1**: 🔴 Disabled due to stream + config errors
- **cobra_cam_2**: 🟡 Recording only, missing detection 
- **cobra_cam_4**: 🟡 Missing authentication in RTSP URL

## 🔧 Step-by-Step Optimization Instructions

### Phase 1: Fix Critical Configuration Errors

#### Step 1.1: Fix cobra_cam_1 Input Roles
**File**: `/etc/nixos/hosts/server/modules/surveillance.nix`
**Location**: Around line 180 in the cobra_cam_1 configuration

1. **Locate the camera configuration block**:
   ```nix
   cobra_cam_1 = {
     ffmpeg = {
       inputs = [
         # Find this section
       ];
     };
   };
   ```

2. **Replace the inputs array** with corrected configuration:
   ```nix
   inputs = [
     {
       path = "rtsp://admin:Fallout123%3F@192.168.1.181:554/stream1";
       roles = [ "detect" "record" ];
     }
     # Remove the second input entirely OR change role to "audio"
   ];
   ```

#### Step 1.2: Enable Detection on cobra_cam_2
**Location**: Around line 220 in surveillance.nix

1. **Find cobra_cam_2 configuration**
2. **Add detect role** to existing inputs:
   ```nix
   inputs = [
     {
       path = "rtsp://admin:Fallout123%3F@192.168.1.182:554/stream1";
       roles = [ "detect" "record" ];  # Add "detect" here
     }
   ];
   ```

#### Step 1.3: Fix cobra_cam_4 Authentication
**Location**: Around line 280 in surveillance.nix

1. **Update RTSP URL** to include credentials:
   ```nix
   path = "rtsp://admin:Fallout123%3F@192.168.1.184:554/stream1";
   ```

### Phase 2: Performance Optimization

#### Step 2.1: Add Motion Masks
**Purpose**: Reduce false detections and improve performance

**For each camera**, add motion mask configuration:
```nix
motion = {
  mask = [
    "0,0,1280,100"        # Top timestamp area
    "0,620,200,720"       # Bottom-left corner
    "1080,620,1280,720"   # Bottom-right corner
  ];
};
```

#### Step 2.2: Optimize Object Detection
**Add object filters** for each camera:
```nix
objects = {
  filters = {
    person = {
      min_area = 5000;
      max_area = 100000;
      threshold = 0.75;
    };
    car = {
      min_area = 15000;
      threshold = 0.7;
    };
  };
};
```

#### Step 2.3: Configure Detection Zones
**Add zones for targeted detection**:
```nix
zones = {
  front_door = {
    coordinates = "640,0,1280,400,1280,720,0,720";
    objects = [ "person" ];
    filters = {
      person = {
        min_area = 3000;
        threshold = 0.8;
      };
    };
  };
};
```

### Phase 3: Storage and Recording Optimization

#### Step 3.1: Standardize Recording Configuration
**Apply consistent recording settings** across all cameras:
```nix
record = {
  enabled = true;
  retain = {
    days = 7;
    mode = "active_objects";
  };
  events = {
    retain = {
      default = 30;
      mode = "active_objects";
    };
  };
};
```

#### Step 3.2: Optimize Buffer Management
**Increase shared memory** if experiencing dropped frames:
```nix
# In container configuration
extraOptions = [
  "--shm-size=1g"  # Increase from 512m to 1g
];
```

### Phase 4: Integration and Automation

#### Step 4.1: Home Assistant Integration
**Enable Frigate integration** in Home Assistant:
1. **Install HACS integration**: Add Frigate integration via HACS
2. **Configure MQTT discovery**: Ensure MQTT broker settings match
3. **Add camera cards** to Home Assistant dashboard

#### Step 4.2: Notification Setup
**Configure event notifications**:
```nix
# Add to Frigate config template
mqtt = {
  host = "127.0.0.1";
  port = 1883;
  topic_prefix = "frigate";
  client_id = "frigate";
  stats_interval = 60;
};
```

#### Step 4.3: Backup Automation
**Create backup service** for important recordings:
```nix
systemd.services.frigate-backup = {
  description = "Backup critical Frigate recordings";
  startAt = "daily";
  script = ''
    # Copy important events to cold storage
    rsync -av /mnt/hot/surveillance/events/ /mnt/media/surveillance/events/
  '';
};
```

### Phase 5: Monitoring and Alerting

#### Step 5.1: Add Frigate Metrics
**Enable Prometheus metrics** in Frigate config:
```yaml
# Add to configuration template
telemetry:
  enabled: true
  port: 5000
```

#### Step 5.2: Create Frigate Dashboard
**File**: `/etc/nixos/hosts/server/modules/grafana-dashboards.nix`

**Add Frigate dashboard configuration**:
```nix
frigate-monitoring = {
  dashboard = {
    title = "Frigate Camera System";
    panels = [
      # CPU usage per camera
      # GPU utilization 
      # Detection rates
      # Storage usage
      # Stream health
    ];
  };
};
```

#### Step 5.3: Configure Alerts
**Add alerting rules** to Prometheus configuration:
```yaml
# Add to alert rules
- alert: FrigateCameraDown
  expr: up{job="frigate"} == 0
  for: 2m
  annotations:
    summary: "Frigate camera system is down"

- alert: FrigateHighCPU
  expr: frigate_cpu_usage > 80
  for: 5m
  annotations:
    summary: "Frigate CPU usage is high"
```

## 🧪 Testing and Validation

### After Each Phase:

1. **Test configuration**:
   ```bash
   sudo nixos-rebuild test --flake .#$(hostname)
   ```

2. **Check Frigate logs**:
   ```bash
   sudo podman logs frigate -f
   ```

3. **Validate camera streams**:
   ```bash
   # Access Frigate web interface at http://localhost:5000
   curl -f http://localhost:5000/api/stats
   ```

4. **Monitor GPU utilization**:
   ```bash
   watch -n 1 nvidia-smi
   ```

### Performance Validation:

- **Detection latency**: Should be <2 seconds per frame
- **GPU utilization**: Should be 20-40% during detection
- **Storage usage**: Monitor /mnt/hot for space usage
- **Stream stability**: No disconnections in logs

## 🚨 Common Issues and Solutions

### Issue: "RTSP connection failed"
**Solution**: Check camera IP addresses and credentials in RTSP URLs

### Issue: "GPU memory allocation failed"  
**Solution**: Reduce detection resolution or limit concurrent processes

### Issue: "High CPU usage"
**Solution**: Add motion masks to reduce processing areas

### Issue: "Storage full"
**Solution**: Implement automatic cleanup or reduce retention periods

## 🔄 Rollback Plan

If issues occur:
1. **Restore backup**: `sudo cp surveillance.nix.backup surveillance.nix`
2. **Rebuild**: `grebuild "Rollback Frigate configuration"`
3. **Check status**: `sudo systemctl status podman-frigate.service`

## 📈 Success Metrics

After optimization:
- ✅ All 4 cameras actively detecting and recording
- ✅ No configuration validation errors
- ✅ GPU utilization 20-40% during operation
- ✅ Home Assistant integration functional
- ✅ Automated notifications working
- ✅ Storage management automated
- ✅ Performance monitoring in place