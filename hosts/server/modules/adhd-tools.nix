{ config, pkgs, ... }:

{
  # ADHD-specific productivity packages
  environment.systemPackages = with pkgs; [
    # Time tracking and monitoring
    python3Packages.psutil  # System monitoring
    python3Packages.schedule  # Task scheduling
    
    # Notification and alerting
    libnotify  # Desktop notifications
    
    # Text processing for context capture
    python3Packages.markdown
    python3Packages.pyyaml
    
    # CLI productivity tools
    tmux  # Session management
    screen  # Alternative session manager
    fzf   # Fuzzy finding (already in home.nix but ensuring it's available system-wide)
  ];
  
  # Create ADHD tools directories
  # ADHD tools directories now created by modules/filesystem/business-directories.nix
  
  # Context Snapshotter service
  systemd.services.context-monitor = {
    description = "ADHD Context Snapshotter - monitors work sessions";
    serviceConfig = {
      Type = "simple";
      User = "eric";
      ExecStart = pkgs.writeShellScript "context-monitor" ''
        #!/bin/bash
        
        # Monitor for deep work sessions and offer context snapshots
        while true; do
          # Check if user has been in terminal for extended period
          ACTIVE_TIME=$(who -u | grep eric | awk '{print $6}' | head -1)
          
          # If in deep work mode, offer context snapshot every 45 minutes
          # This prevents hyperfocus rabbit holes
          
          sleep 2700  # 45 minutes
          
          # Send notification if user is still active
          if pgrep -u eric -x zsh > /dev/null || pgrep -u eric -x bash > /dev/null; then
            ${pkgs.libnotify}/bin/notify-send "🧠 Context Snapshot" "You've been working for 45+ minutes. Save your current context?" -t 10000
          fi
        done
      '';
      Restart = "always";
      RestartSec = "60";
    };
    # Don't auto-start - user can enable when needed
    wantedBy = [ ];
  };
  
  # Energy and productivity correlation tracker
  environment.etc."adhd-tools/energy-tracker.py" = {
    text = ''
      #!/usr/bin/env python3
      """
      Energy and Productivity Correlation Tracker for ADHD Management
      
      Tracks:
      - Time of day vs productivity
      - Supplement timing vs focus levels  
      - Break patterns vs sustained attention
      - Context switching frequency
      """
      
      import json
      import datetime
      from pathlib import Path
      
      class EnergyTracker:
          def __init__(self):
              self.data_file = Path("/opt/adhd-tools/energy-tracking/daily_data.json")
              self.data_file.parent.mkdir(exist_ok=True)
          
          def log_energy_level(self, level, context=""):
              """Log current energy/focus level (1-10 scale)"""
              entry = {
                  "timestamp": datetime.datetime.now().isoformat(),
                  "energy_level": level,
                  "context": context
              }
              
              # Append to daily log
              data = []
              if self.data_file.exists():
                  with open(self.data_file) as f:
                      data = json.load(f)
              
              data.append(entry)
              
              with open(self.data_file, 'w') as f:
                  json.dump(data, f, indent=2)
              
              print(f"✅ Logged energy level: {level}/10 at {entry['timestamp'][:16]}")
      
      if __name__ == "__main__":
          import sys
          if len(sys.argv) != 2:
              print("Usage: energy-tracker.py <energy_level_1-10>")
              sys.exit(1)
          
          level = int(sys.argv[1])
          if not 1 <= level <= 10:
              print("Energy level must be between 1-10")
              sys.exit(1)
          
          tracker = EnergyTracker()
          tracker.log_energy_level(level)
    '';
    mode = "0755";
  };
}
