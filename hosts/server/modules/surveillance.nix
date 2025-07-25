{ config, lib, pkgs, ... }:

let
  cfg = config.heartwood.paths;
  # Common container patterns using path configuration
  localtime = "/etc/localtime:/etc/localtime:ro";
  frigatePath = "${cfg.surveillanceRoot}/frigate";
  homeAssistantPath = "${cfg.surveillanceRoot}/home-assistant";
  
  # GPU environment variables
  nvidiaEnv = {
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
  };
in
{
  environment.systemPackages = with pkgs; [
    ffmpeg
    mosquitto
  ];

  services.mosquitto = {
    enable = true;
    listeners = [{
      address = "127.0.0.1";
      port = 1883;
      acl = [ "pattern readwrite #" ];
      omitPasswordAuth = true;
      settings.allow_anonymous = true;
    }];
  };

  systemd.services.frigate-config = {
    description = "Generate Frigate configuration";
    wantedBy = [ "podman-frigate.service" ];
    before = [ "podman-frigate.service" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      mkdir -p /opt/surveillance/frigate/config
      cat > /opt/surveillance/frigate/config/config.yaml << 'EOF'
mqtt:
  enabled: true
  host: 127.0.0.1
  port: 1883

detectors:
  tensorrt:
    type: tensorrt
    device: 0
    model:
      path: /config/model_cache/tensorrt/yolov7-320.trt
      input_tensor: nchw
      input_pixel_format: rgb
      width: 320
      height: 320

ffmpeg: &ffmpeg_defaults
  hwaccel_args:
    - -hwaccel
    - cuda
    - -hwaccel_device
    - "0"
    - -hwaccel_output_format
    - yuv420p
  input_args:
    - -rtsp_transport
    - tcp
    - -fflags
    - +genpts+discardcorrupt
    - -avoid_negative_ts
    - make_zero
    - -analyzeduration
    - "20000000"
    - -probesize
    - "20000000"
    - -reconnect
    - "1"
    - -reconnect_streamed
    - "1"
    - -reconnect_delay_max
    - "5"

cameras:
  cobra_cam_1:
    enabled: false  # Temporarily disabled - camera stream issues
    ffmpeg:
      <<: *ffmpeg_defaults
      inputs:
        - path: rtsp://admin:il0wwlm%3F@192.168.1.101:554/ch01/0
          roles: [ detect, record ]
        - path: rtsp://admin:il0wwlm%3F@192.168.1.101:554/ch01/1  
          roles: [ record ]
    detect:
      enabled: true
      width: 640  # Reduced from 1280 
      height: 360 # Reduced from 720
      fps: 2      # Reduced from 3
    record:
      enabled: true
      retain:
        days: 7
        mode: active_objects
    objects:
      track: [ person, car, truck ]

  cobra_cam_2:
    ffmpeg:
      <<: *ffmpeg_defaults
      inputs:
        - path: rtsp://admin:il0wwlm%3F@192.168.1.102:554/ch01/0
          roles: [ record ]
    detect:
      enabled: true
      width: 640  # Reduced resolution
      height: 360
      fps: 2
    record:
      enabled: true
      retain:
        days: 7
        mode: active_objects
    objects:
      track: [ person, car, truck ]

  cobra_cam_3:
    ffmpeg:
      <<: *ffmpeg_defaults
      inputs:
        - path: rtsp://admin:il0wwlm%3F@192.168.1.103:554/ch01/0
          roles: [ detect, record ]
    detect:
      enabled: true
      width: 320
      height: 240
      fps: 3
    record:
      enabled: true
      retain:
        days: 7
        mode: motion
    snapshots:
      enabled: true
      timestamp: true
      bounding_box: true
      retain:
        default: 14
    zones:
      sidewalk:
        coordinates: "0.132,0.468,0.996,0.7,0.993,0.998,0.003,0.996,0.007,0.5"
        objects:
          - person
          - car
          - truck
          - bicycle
          - motorcycle

  cobra_cam_4:
    ffmpeg:
      <<: *ffmpeg_defaults
      inputs:
        - path: rtsp://192.168.1.104:554/ch01/0
          roles: [ record ]
    detect:
      enabled: false
    record:
      enabled: true
      retain:
        days: 7
        mode: motion

objects:
  track: [ person, car, truck, bicycle, motorcycle, dog, cat ]

go2rtc:
  streams:
    cobra_cam_1: [ "rtsp://admin:il0wwlm%3F@192.168.1.101:554/ch01/0" ]
    cobra_cam_2: [ "rtsp://admin:il0wwlm%3F@192.168.1.102:554/ch01/0" ]
    cobra_cam_3: [ "rtsp://admin:il0wwlm%3F@192.168.1.103:554/ch01/0" ]
    cobra_cam_4: [ "rtsp://192.168.1.104:554/ch01/0" ]

ui:
  live_mode: mse
  timezone: America/Denver

record:
  enabled: true
  retain:
    days: 7
    mode: motion
  events:
    retain:
      default: 30
      mode: motion
    objects:
      person:
        required_zones: []
      car:
        required_zones: []
      truck:
        required_zones: []

motion:
  threshold: 25
  contour_area: 15
  delta_alpha: 0.2
  frame_alpha: 0.01
  frame_height: 100
  improve_contrast: true

logger:
  default: info
  logs:
    frigate.record: debug
    frigate.detect: info
    frigate.detectors.plugins.tensorrt: debug
EOF
      chown eric:users /opt/surveillance/frigate/config/config.yaml
    '';
  };

  virtualisation.oci-containers.containers = {
    frigate = {
      image = "ghcr.io/blakeblackshear/frigate:stable-tensorrt";
      autoStart = true;
      extraOptions = [
        "--network=host"
        "--device=nvidia.com/gpu=0"
        "--security-opt=label=disable"
        "--privileged"
        "--tmpfs=/tmp/cache:size=1g"
        "--shm-size=512m"
        "--memory=4g"        # Reduced from 6g
        "--cpus=1.5"         # Reduced from 2.0
      ];
      environment = {
        FRIGATE_RTSP_PASSWORD = "il0wwlm?";
        TZ = "America/Denver";
        
        # Critical: TensorRT model generation for Pascal architecture
        YOLO_MODELS = "yolov7-320";
        USE_FP16 = "false";  # Required for Pascal (P1000) - Tensor cores need FP16 disabled
        
        # Reduce detection load temporarily
        FRIGATE_DEFAULT_DETECT_FPS = "1";  # Reduce from 3 to 1 FPS
        
              # GPU acceleration environment
        LIBVA_DRIVER_NAME = "nvidia";
        VDPAU_DRIVER = "nvidia";
        # Add library path for NVIDIA libraries  
        LD_LIBRARY_PATH = "/run/opengl-driver/lib:/run/opengl-driver-32/lib";
      } // nvidiaEnv;
      volumes = [
        "/opt/surveillance/frigate/config:/config"
        "/mnt/media/surveillance/frigate/media:/media/frigate"
        "/mnt/hot/surveillance/buffer:/tmp/frigate"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };

    home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      autoStart = true;
      extraOptions = [ "--network=host" ];
      environment = {
        TZ = "America/Denver";
      };
      volumes = [
        "${homeAssistantPath}/config:/config"
        localtime
      ];
    };
  };

  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 5000 8123 8554 8555 1883 ];
    allowedUDPPorts = [ 8555 ];
  };
}
