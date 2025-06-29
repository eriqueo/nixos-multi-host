# hosts/server/modules/media-monitor-setup.nix
# Setup for custom media pipeline monitoring
{ config, lib, pkgs, ... }:

{
  # Install monitoring script and dependencies
  systemd.services.media-monitor-setup = {
    description = "Setup media pipeline monitor";
    wantedBy = [ "podman-media-pipeline-monitor.service" ];
    before = [ "podman-media-pipeline-monitor.service" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      # Create monitoring directory
      mkdir -p /opt/monitoring/media-monitor
      
      # Copy monitoring script
      cp ${./media-monitor.py} /opt/monitoring/media-monitor/media_monitor.py
      chmod +x /opt/monitoring/media-monitor/media_monitor.py
      
      # Create requirements.txt
      cat > /opt/monitoring/media-monitor/requirements.txt << 'EOF'
prometheus_client==0.18.0
psutil==5.9.6
requests==2.31.0
EOF

      # Create Dockerfile for the monitor
      cat > /opt/monitoring/media-monitor/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy monitoring script
COPY media_monitor.py .

# Run the monitor
CMD ["python", "media_monitor.py"]
EOF

      # Set permissions
      chown -R eric:users /opt/monitoring/media-monitor/
    '';
  };
}