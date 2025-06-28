{ config, pkgs, ... }:
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

  systemd.tmpfiles.rules = [
    "d /opt/surveillance 0755 eric users -"
    "d /opt/surveillance/frigate 0755 eric users -"
    "d /opt/surveillance/frigate/config 0755 eric users -"
    "d /opt/surveillance/frigate/media 0755 eric users -"
    "d /opt/surveillance/home-assistant 0755 eric users -"
    "d /opt/surveillance/home-assistant/config 0755 eric users -"
    "d /tmp/frigate-cache 0755 eric users -"
    "d /var/lib/tailscale 0755 root root -"
    "d /var/lib/tailscale/certs 0755 root root -"
  ];

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
  cpu1:
    type: cpu
    num_threads: 2

ffmpeg: &ffmpeg_defaults
  input_args:
    - -rtsp_transport
    - tcp
    - -fflags
    - +genpts
    - -avoid_negative_ts
    - make_zero

cameras:
  cobra_cam_1:
    ffmpeg:
      <<: *ffmpeg_defaults
      inputs:
        - path: rtsp://admin:il0wwlm%3F@192.168.1.101:554/ch01/0
          roles: [ record ]
    detect:
      enabled: true
      width: 1280
      height: 720
      fps: 3
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
      width: 1280
      height: 720
      fps: 3
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
EOF
      chown eric:users /opt/surveillance/frigate/config/config.yaml
    '';
  };

  virtualisation.oci-containers.containers = {
#    frigate = {
#      image = "ghcr.io/blakeblackshear/frigate:stable";
#      autoStart = true;
#      extraOptions = [
#        "--privileged"
#        "--network=host"
#        "--device=/dev/dri:/dev/dri"
#        "--tmpfs=/tmp/cache:size=1g"
#        "--shm-size=512m"
#        "--memory=6g"
#        "--cpus=2.0"
#      ];
#      environment = {
#        FRIGATE_RTSP_PASSWORD = "il0wwlm?";
#        TZ = "America/Denver";
#        LIBVA_DRIVER_NAME = "i965";
#        FRIGATE_BASE_PATH = "/cameras";
#      };
#     volumes = [
#        "/opt/surveillance/frigate/config:/config"
#        "/mnt/media/surveillance/frigate/media:/media/frigate"
#        "/etc/localtime:/etc/localtime:ro"
#      ];
#      ports = [
#        "5000:5000"
#        "8554:8554"
#        "8555:8555/tcp"
#        "8555:8555/udp"
#      ];
#    };

    home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      autoStart = true;
      extraOptions = [ "--network=host" ];
      environment = {
        TZ = "America/Denver";
      };
      volumes = [
        "/opt/surveillance/home-assistant/config:/config"
        "/etc/localtime:/etc/localtime:ro"
      ];
      ports = [ "8123:8123" ];
    };
  };

  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 5000 8123 8554 8555 1883 ];
    allowedUDPPorts = [ 8555 ];
  };
}
