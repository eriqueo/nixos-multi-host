# modules.nix - Heartwood Craft Service Modules
{ config, lib, pkgs, ... }:

{
  # 📺 MEDIA SERVER SERVICES
  
  # Native Jellyfin service
  services.jellyfin = lib.mkIf config.media.server {
    enable = true;
  };

  # Container services
  virtualisation.oci-containers.containers = lib.mkMerge [
    
    # Media Stack (server only)
    (lib.mkIf config.media.server {
      gluetun = {
        image = "qmcgaw/gluetun:latest";
        autoStart = true;
        extraOptions = [ "--cap-add=NET_ADMIN" "--device=/dev/net/tun" ];
        environment = {
          VPN_SERVICE_PROVIDER = "protonvpn";
          VPN_TYPE = "wireguard";
          # TODO: Replace with your actual ProtonVPN WireGuard key
          WIREGUARD_PRIVATE_KEY = "qKjVz3ubVdGMbVGVOBiX/K5pRKtAf4p/oBXiiUis11c=";
          WIREGUARD_ADDRESSES = "10.2.0.2/32";
          SERVER_COUNTRIES = "Netherlands";
          TZ = "NL#340";
        };
        ports = [ "8080:8080" ];
      };

      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        autoStart = true;
        dependsOn = [ "gluetun" ];
        extraOptions = [ "--network=container:gluetun" ];
        volumes = [
          "/opt/downloads/qbittorrent:/config"
          "/mnt/media/downloads:/downloads"
          "/mnt/media:/media"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
          WEBUI_PORT = "8080";
        };
      };

      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        autoStart = true;
        ports = [ "8989:8989" ];
        volumes = [
          "/opt/downloads/sonarr:/config"
          "/mnt/media:/media"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
        };
      };

      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        autoStart = true;
        ports = [ "7878:7878" ];
        volumes = [
          "/opt/downloads/radarr:/config"
          "/mnt/media:/media"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
        };
      };

      lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        autoStart = true;
        ports = [ "8686:8686" ];
        volumes = [
          "/opt/downloads/lidarr:/config"
          "/mnt/media:/media"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
        };
      };

      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        autoStart = true;
        ports = [ "9696:9696" ];
        volumes = [
          "/opt/downloads/prowlarr:/config"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
        };
      };

      navidrome = {
        image = "deluan/navidrome:latest";
        autoStart = true;
        ports = [ "4533:4533" ];
        volumes = [
          "/opt/downloads/navidrome:/data"
          "/mnt/media/music:/music:ro"
        ];
        environment = {
          ND_SCANSCHEDULE = "1h";
          ND_LOGLEVEL = "info";
          ND_SESSIONTIMEOUT = "24h";
          ND_BASEURL = "";
          TZ = "America/Denver";
        };
      };

      immich = {
        image = "ghcr.io/immich-app/immich-server:release";
        autoStart = true;
        ports = [ "2283:3001" ];
        volumes = [
          "/opt/downloads/immich:/usr/src/app/upload"
          "/mnt/media/pictures:/usr/src/app/external:ro"
        ];
        environment = {
          DB_HOSTNAME = "immich-postgres";
          DB_USERNAME = "postgres";
          DB_PASSWORD = "postgres";
          DB_DATABASE_NAME = "immich";
          REDIS_HOSTNAME = "immich-redis";
          TZ = "America/Denver";
        };
        dependsOn = [ "immich-postgres" "immich-redis" ];
      };

      immich-postgres = {
        image = "tensorchord/pgvecto-rs:pg14-v0.2.0";
        autoStart = true;
        volumes = [
          "/opt/downloads/immich/postgres:/var/lib/postgresql/data"
        ];
        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_PASSWORD = "postgres";
          POSTGRES_DB = "immich";
          TZ = "America/Denver";
        };
      };

      immich-redis = {
        image = "redis:6.2-alpine";
        autoStart = true;
        environment = {
          TZ = "America/Denver";
        };
      };
    })

    # Surveillance Stack (server only)
    (lib.mkIf config.surveillance.server {
      frigate = {
        image = "ghcr.io/blakeblackshear/frigate:stable";
        autoStart = true;
        extraOptions = [
          "--privileged"
          "--network=host"
          "--device=/dev/dri:/dev/dri"
          "--tmpfs=/tmp/cache:size=1g"
          "--shm-size=512m"
	  "--memory =6g"
	  "--cpus=2.0"
        ];
        environment = {
          FRIGATE_RTSP_PASSWORD = "iL0wwlm?";
          TZ = "America/Denver";
          LIBVA_DRIVER_NAME = "i965";
        };
        volumes = [
          "/opt/surveillance/frigate/config:/config"
          "/mnt/media/surveillance/frigate/media:/media/frigate"
          "/etc/localtime:/etc/localtime:ro"
        ];
        ports = [
          "5000:5000"
          "8554:8554"
          "8555:8555/tcp"
          "8555:8555/udp"
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
          "/opt/surveillance/home-assistant/config:/config"
          "/etc/localtime:/etc/localtime:ro"
        ];
        ports = [ "8123:8123" ];
      };
    })
  ];

  # 💼 BUSINESS INTELLIGENCE SERVICES

  # PostgreSQL database (server only)
  services.postgresql = lib.mkIf config.business.server {
    enable = true;
    package = pkgs.postgresql_15;
    
    # TODO: Change 'secure_password_change_me' to a real password
    initialScript = pkgs.writeText "postgres-init.sql" ''
      CREATE DATABASE heartwood_business;
      CREATE USER business_user WITH PASSWORD 'yJQlVUd934UhmC+gA2or9yZrhWJz5cgniuYA+ePAcaU=';
      GRANT ALL PRIVILEGES ON DATABASE heartwood_business TO business_user;
      
      \c heartwood_business;
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      
      CREATE TABLE IF NOT EXISTS projects (
          id SERIAL PRIMARY KEY,
          jobtread_id VARCHAR(50) UNIQUE,
          project_name VARCHAR(255) NOT NULL,
          client_name VARCHAR(255) NOT NULL,
          project_type VARCHAR(100),
          start_date DATE,
          estimated_completion DATE,
          actual_completion DATE,
          total_budget DECIMAL(12,2),
          contract_amount DECIMAL(12,2),
          project_status VARCHAR(50),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      
      CREATE TABLE IF NOT EXISTS receipts (
          id SERIAL PRIMARY KEY,
          project_id INTEGER REFERENCES projects(id),
          receipt_image_path VARCHAR(500) NOT NULL,
          vendor_name VARCHAR(255),
          purchase_date DATE,
          total_amount DECIMAL(10,2),
          tax_amount DECIMAL(10,2),
          ocr_raw_text TEXT,
          ocr_confidence DECIMAL(3,2),
          processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      
      CREATE TABLE IF NOT EXISTS receipt_items (
          id SERIAL PRIMARY KEY,
          receipt_id INTEGER REFERENCES receipts(id),
          item_description VARCHAR(500),
          quantity DECIMAL(8,2),
          unit_price DECIMAL(8,2),
          line_total DECIMAL(10,2),
          material_category VARCHAR(100),
          budget_category VARCHAR(100)
      );
    '';
    
    settings = {
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
    };
    
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 md5
      host all all ::1/128 md5
    '';
  };

  # Redis cache (server only)
  services.redis.servers.business = lib.mkIf config.business.server {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
  };

  # 🤖 AI SERVICES

  # Ollama AI service (server only)
  services.ollama = lib.mkIf config.ai.server {
    enable = true;
    acceleration = false; # CPU-only for data sovereignty
    host = "127.0.0.1";
    port = 11434;
  };

  # 📹 SURVEILLANCE CONFIGURATION

  # MQTT broker (server only)
  services.mosquitto = lib.mkIf config.surveillance.server {
    enable = true;
    listeners = [{
      address = "127.0.0.1";
      port = 1883;
      acl = [ "pattern readwrite #" ];
      omitPasswordAuth = true;
      settings.allow_anonymous = true;
    }];
  };

  # Frigate configuration service (server only)
  systemd.services.frigate-config = lib.mkIf config.surveillance.server {
    description = "Generate Frigate configuration";
    wantedBy = [ "podman-frigate.service" ];
    before = [ "podman-frigate.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
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
      enabled: false
    record: { enabled: true, retain: { days: 7, mode: motion } }
    motion:
      mask:
        - "0.506,0.004,0.521,0.147,0.632,0.417,0.857,0.627,0.892,0.663,0.863,0.79,0.925,1,1,0.993,0.996,0.009"
    
  cobra_cam_2:
    ffmpeg:
      <<: *ffmpeg_defaults
      inputs:
        - path: rtsp://admin:il0wwlm%3F@192.168.1.102:554/ch01/0
          roles: [ record ]
    detect:
      enabled: false
    record: { enabled: true, retain: { days: 7, mode: motion } }
    motion:
      mask:
        - "0.095,0.507,0.261,0.578,0.251,0.743,0.08,0.708"
        - "0.328,0.229,0.262,0.144,0.208,0.326,0.28,0.383,0.482,0.323,0.488,0.295"
    
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
    record: { enabled: true, retain: { days: 7, mode: motion } }
    snapshots: { enabled: true, timestamp: true, bounding_box: true, retain: { default: 14 } }
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
    record: { enabled: true, retain: { days: 7, mode: motion } }

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
    objects: [ person, car, truck ]

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

  # 📁 STORAGE CONFIGURATION

  # Create required directories (server only)
  systemd.tmpfiles.rules = lib.mkIf config.server [
    # Media directories
    "d /mnt/media 0755 eric users -"
    "d /mnt/media/tv 0755 eric users -"
    "d /mnt/media/movies 0755 eric users -"
    "d /mnt/media/music 0755 eric users -"
    "d /mnt/media/pictures 0755 eric users -"
    "d /mnt/media/downloads 0755 eric users -"
    "d /mnt/media/surveillance 0755 eric users -"
    "d /mnt/media/surveillance/frigate 0755 eric users -"
    "d /mnt/media/surveillance/frigate/media 0755 eric users -"
    
    # Container config directories
    "d /opt/downloads 0755 eric users -"
    "d /opt/downloads/qbittorrent 0755 eric users -"
    "d /opt/downloads/sonarr 0755 eric users -"
    "d /opt/downloads/radarr 0755 eric users -"
    "d /opt/downloads/lidarr 0755 eric users -"
    "d /opt/downloads/prowlarr 0755 eric users -"
    "d /opt/downloads/navidrome 0755 eric users -"
    "d /opt/downloads/immich 0755 eric users -"
    "d /opt/downloads/immich/postgres 0755 eric users -"
    
    # Surveillance directories
    "d /opt/surveillance 0755 eric users -"
    "d /opt/surveillance/frigate 0755 eric users -"
    "d /opt/surveillance/frigate/config 0755 eric users -"
    "d /opt/surveillance/home-assistant 0755 eric users -"
    "d /opt/surveillance/home-assistant/config 0755 eric users -"
    
    # Business directories
    "d /opt/business 0755 eric users -"
    "d /opt/business/api 0755 eric users -"
    "d /opt/business/dashboard 0755 eric users -"
    "d /opt/business/receipts 0755 eric users -"
    "d /opt/business/uploads 0755 eric users -"
    "d /opt/business/processed 0755 eric users -"
    "d /opt/business/backups 0755 eric users -"
    
    # ADHD tools
    "d /opt/adhd-tools 0755 eric users -"
    "d /opt/adhd-tools/context-snapshots 0755 eric users -"
    "d /opt/adhd-tools/energy-tracking 0755 eric users -"
    "d /opt/adhd-tools/focus-logs 0755 eric users -"
    "d /opt/adhd-tools/scripts 0755 eric users -"
    
    # AI directories
    "d /opt/ai 0755 eric users -"
    "d /opt/ai/models 0755 eric users -"
    "d /opt/ai/context-snapshots 0755 eric users -"
    "d /opt/ai/document-embeddings 0755 eric users -"
  ];

  # Business packages (server)
  
  # Combined package configuration
  environment.systemPackages = 
    # Business server packages
    lib.optionals config.business.server (with pkgs; [
      tesseract imagemagick poppler_utils
      python3Packages.fastapi python3Packages.uvicorn
      python3Packages.sqlalchemy python3Packages.alembic
      python3Packages.psycopg2 python3Packages.asyncpg
      python3Packages.pandas python3Packages.streamlit
      python3Packages.python-multipart python3Packages.python-dotenv
      python3Packages.pillow python3Packages.opencv4
      python3Packages.pytesseract python3Packages.pdf2image
      python3Packages.httpx python3Packages.requests
      python3Packages.plotly python3Packages.altair
      python3Packages.torch python3Packages.transformers
      python3Packages.sentence-transformers python3Packages.langchain
      python3Packages.openai python3Packages.numpy
      python3Packages.scikit-learn python3Packages.matplotlib
      python3Packages.seaborn postgresql
    ])
    # Client packages
	++ lib.optionals (config.media.client || config.business.client || config.surveillance.client) (with pkgs; [
  	ffmpeg-full vlc mpv cifs-utils postgresql
	]);

  # AI model setup service (server only)
  systemd.services.ai-model-setup = lib.mkIf config.ai.server {
    description = "Download and configure business-focused AI models";
    serviceConfig = {
      Type = "oneshot";
      User = "eric";
      ExecStart = pkgs.writeShellScript "setup-ai-models" ''
        # Wait for Ollama service to be ready
        sleep 10
        
        # Download efficient business-focused models
        ${pkgs.ollama}/bin/ollama pull llama3.2:3b
        ${pkgs.ollama}/bin/ollama pull nomic-embed-text
        
        echo "AI models ready for business intelligence processing"
        echo "Chat model: llama3.2:3b"
        echo "Embeddings: nomic-embed-text"
      '';
    };
    wantedBy = [ "multi-user.target" ];
    after = [ "ollama.service" ];
    requires = [ "ollama.service" ];
  };

  # Business database backup service (server only)
  systemd.services.business-backup = lib.mkIf config.business.server {
    description = "Daily backup of business database";
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStart = pkgs.writeShellScript "business-backup" ''
        DATE=$(date +%Y%m%d_%H%M%S)
        ${pkgs.postgresql}/bin/pg_dump \
          -U business_user \
          -h localhost \
          heartwood_business \
          | gzip > /opt/business/backups/heartwood_business_$DATE.sql.gz
        
        # Retain only last 30 days of backups
        find /opt/business/backups -name "heartwood_business_*.sql.gz" -mtime +30 -delete
        
        echo "Database backup completed: heartwood_business_$DATE.sql.gz"
      '';
    };
  };

  # Schedule daily backups at 2 AM (server only)
  systemd.timers.business-backup = lib.mkIf config.business.server {
    description = "Daily business database backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "02:00";
      Persistent = true;
    };
  };

  # ADHD tools scripts deployment (server only)
  environment.etc = lib.mkIf config.business.server {
    "adhd-tools/energy-tracker.py" = {
      text = ''
        #!/usr/bin/env python3
        """
        Energy and Productivity Correlation Tracker for ADHD Management
        
        Usage: energy-tracker.py <energy_level_1-10> [context_note]
               energy-tracker.py --stats  (show energy patterns)
        """
        
        import json
        import datetime
        import sys
        from pathlib import Path
        
        class EnergyTracker:
            def __init__(self):
                self.data_file = Path("/opt/adhd-tools/energy-tracking/daily_data.json")
                self.data_file.parent.mkdir(parents=True, exist_ok=True)
            
            def log_energy_level(self, level, context=""):
                """Log current energy/focus level with timestamp and context"""
                entry = {
                    "timestamp": datetime.datetime.now().isoformat(),
                    "energy_level": level,
                    "context": context,
                    "hour_of_day": datetime.datetime.now().hour,
                    "day_of_week": datetime.datetime.now().strftime("%A")
                }
                
                # Load existing data
                data = []
                if self.data_file.exists():
                    try:
                        with open(self.data_file) as f:
                            data = json.load(f)
                    except (json.JSONDecodeError, FileNotFoundError):
                        data = []
                
                # Append new entry
                data.append(entry)
                
                # Save updated data
                with open(self.data_file, 'w') as f:
                    json.dump(data, f, indent=2)
                
                print(f"✅ Logged energy level: {level}/10 at {entry['timestamp'][:16]}")
                
                # Provide contextual feedback
                if level <= 3:
                    print("💤 Low energy detected. Consider break or energy-boosting activity.")
                elif level >= 8:
                    print("⚡ High energy! Good time for challenging tasks.")
            
            def get_energy_patterns(self, days_back=7):
                """Analyze energy patterns over specified time period"""
                if not self.data_file.exists():
                    return None
                
                with open(self.data_file) as f:
                    data = json.load(f)
                
                # Filter recent entries
                cutoff_date = datetime.datetime.now() - datetime.timedelta(days=days_back)
                recent_data = [
                    entry for entry in data 
                    if datetime.datetime.fromisoformat(entry['timestamp']) > cutoff_date
                ]
                
                if not recent_data:
                    return None
                
                # Calculate patterns
                hourly_avg = {}
                daily_avg = {}
                
                for entry in recent_data:
                    hour = entry['hour_of_day']
                    day = entry['day_of_week']
                    level = entry['energy_level']
                    
                    if hour not in hourly_avg:
                        hourly_avg[hour] = []
                    if day not in daily_avg:
                        daily_avg[day] = []
                    
                    hourly_avg[hour].append(level)
                    daily_avg[day].append(level)
                
                # Calculate averages
                for hour in hourly_avg:
                    hourly_avg[hour] = sum(hourly_avg[hour]) / len(hourly_avg[hour])
                for day in daily_avg:
                    daily_avg[day] = sum(daily_avg[day]) / len(daily_avg[day])
                
                return {
                    "total_entries": len(recent_data),
                    "average_energy": sum(entry['energy_level'] for entry in recent_data) / len(recent_data),
                    "best_hours": sorted(hourly_avg.items(), key=lambda x: x[1], reverse=True)[:3],
                    "best_days": sorted(daily_avg.items(), key=lambda x: x[1], reverse=True)[:3]
                }
        
        def main():
            if len(sys.argv) < 2:
                print("Usage: energy-tracker.py <energy_level_1-10> [context_note]")
                print("       energy-tracker.py --stats  (show energy patterns)")
                sys.exit(1)
            
            tracker = EnergyTracker()
            
            if sys.argv[1] == "--stats":
                patterns = tracker.get_energy_patterns()
                if patterns:
                    print(f"\n📊 Energy Patterns (last 7 days):")
                    print(f"Average Energy: {patterns['average_energy']:.1f}/10")
                    print(f"Total Entries: {patterns['total_entries']}")
                    print(f"Best Hours: {', '.join([f'{h}:00 ({avg:.1f})' for h, avg in patterns['best_hours']])}")
                    print(f"Best Days: {', '.join([f'{day} ({avg:.1f})' for day, avg in patterns['best_days']])}")
                else:
                    print("No energy data available. Start logging with: energy-log <1-10>")
                return
            
            try:
                level = int(sys.argv[1])
                if not 1 <= level <= 10:
                    raise ValueError("Energy level must be between 1-10")
                
                context = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else ""
                tracker.log_energy_level(level, context)
                
            except ValueError as e:
                print(f"Error: {e}")
                sys.exit(1)
        
        if __name__ == "__main__":
            main()
      '';
      mode = "0755";
    };
    
    "adhd-tools/context-snapshot.py" = {
      text = ''
        #!/usr/bin/env python3
        """
        Context Snapshot Utility for ADHD Workflow Management
        
        Usage: context-snapshot.py [project_name]
               context-snapshot.py --list
               context-snapshot.py --restore <snapshot_name>
        """
        
        import os
        import json
        import datetime
        import subprocess
        import sys
        from pathlib import Path
        
        class ContextSnapshotter:
            def __init__(self):
                self.snapshots_dir = Path("/opt/adhd-tools/context-snapshots")
                self.snapshots_dir.mkdir(parents=True, exist_ok=True)
            
            def capture_context(self, project_name=None):
                """Capture comprehensive work context"""
                timestamp = datetime.datetime.now().isoformat()
                
                context = {
                    "timestamp": timestamp,
                    "project_name": project_name or "general",
                    "current_directory": os.getcwd(),
                    "environment_variables": {
                        "PWD": os.getenv("PWD"),
                        "PROJECTS": os.getenv("PROJECTS"),
                        "USER": os.getenv("USER")
                    },
                    "recent_commands": self.get_recent_commands(),
                    "active_processes": self.get_active_processes(),
                    "system_state": {
                        "load_average": list(os.getloadavg()) if hasattr(os, 'getloadavg') else [],
                        "working_directory_contents": os.listdir(".") if os.path.exists(".") else []
                    }
                }
                
                # Prompt for additional context
                try:
                    context["energy_level"] = input("Current energy level (1-10): ")
                    context["current_focus"] = input("What are you working on? ")
                    context["next_steps"] = input("Next steps when you return: ")
                    context["blockers"] = input("Any blockers or issues? ")
                except (EOFError, KeyboardInterrupt):
                    context["note"] = "Automated context capture"
                
                # Save snapshot
                filename = f"context_{timestamp.replace(':', '-')[:19]}.json"
                filepath = self.snapshots_dir / filename
                
                with open(filepath, 'w') as f:
                    json.dump(context, f, indent=2)
                
                print(f"✅ Context snapshot saved: {filename}")
                return filepath
            
            def get_recent_commands(self):
                """Get recent shell commands from history"""
                try:
                    history_file = Path.home() / ".zsh_history"
                    if history_file.exists():
                        with open(history_file, 'r', errors='ignore') as f:
                            lines = f.readlines()
                        return [line.strip() for line in lines[-10:]]
                except Exception:
                    pass
                return []
            
            def get_active_processes(self):
                """Get currently running user processes"""
                try:
                    result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
                    lines = result.stdout.split('\n')
                    user_processes = [line for line in lines if os.getenv('USER', 'eric') in line]
                    return user_processes[:10]
                except Exception:
                    return []
            
            def list_snapshots(self):
                """List available context snapshots"""
                snapshots = sorted(self.snapshots_dir.glob("context_*.json"), reverse=True)
                return [(f.name, f.stat().st_mtime) for f in snapshots[:10]]
            
            def restore_context(self, snapshot_name):
                """Display context snapshot for manual restoration"""
                filepath = self.snapshots_dir / snapshot_name
                if not filepath.exists():
                    print(f"Snapshot not found: {snapshot_name}")
                    return
                
                with open(filepath) as f:
                    context = json.load(f)
                
                print(f"\n📋 Context Snapshot: {context.get('project_name', 'Unknown')}")
                print(f"⏰ Captured: {context['timestamp']}")
                print(f"📁 Directory: {context['current_directory']}")
                print(f"⚡ Energy Level: {context.get('energy_level', 'Not recorded')}")
                print(f"🎯 Focus: {context.get('current_focus', 'Not recorded')}")
                print(f"➡️  Next Steps: {context.get('next_steps', 'Not recorded')}")
                if context.get('blockers'):
                    print(f"🚫 Blockers: {context['blockers']}")
                
                if context.get('recent_commands'):
                    print(f"\n📜 Recent Commands:")
                    for cmd in context['recent_commands'][-5:]:
                        print(f"   {cmd}")
        
        def main():
            snapshotter = ContextSnapshotter()
            
            if len(sys.argv) > 1:
                if sys.argv[1] == "--list":
                    snapshots = snapshotter.list_snapshots()
                    if snapshots:
                        print("📸 Available Context Snapshots:")
                        for name, mtime in snapshots:
                            date_str = datetime.datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")
                            print(f"   {name} ({date_str})")
                    else:
                        print("No context snapshots found")
                    return
                elif sys.argv[1] == "--restore":
                    if len(sys.argv) < 3:
                        print("Usage: context-snapshot.py --restore <snapshot_name>")
                        return
                    snapshotter.restore_context(sys.argv[2])
                    return
                else:
                    # Treat as project name
                    snapshotter.capture_context(sys.argv[1])
            else:
                snapshotter.capture_context()
        
        if __name__ == "__main__":
            main()
      '';
      mode = "0755";
    };
  };
}
