# AI Documentation Services Configuration - HARDENED VERSION
# 
# UPDATED: Separated AI documentation from grebuild workflow with hardening
# - Lightweight post-commit hook for logging only
# - AI processing now triggered AFTER successful rebuilds
# - HARDENED: Process locking prevents drift between commits
# - HARDENED: Git push error handling with notifications
# - Prevents blocking grebuild function with slow AI processing

{ config, pkgs, ... }:

{
  # AI and ML packages
  environment.systemPackages = with pkgs; [
    # Essential AI tools (keep enabled)
    ollama
    
    # Heavy AI/ML packages (commented out for faster builds)
    # Uncomment after initial system setup:
    # python3Packages.torch
    # python3Packages.transformers
    # python3Packages.sentence-transformers
    # python3Packages.chromadb  # Vector database for RAG
    # python3Packages.langchain
    # python3Packages.openai  # For API compatibility
    
    # Lightweight ML libraries (keep enabled)
    python3Packages.numpy
    python3Packages.scikit-learn
    python3Packages.matplotlib
    python3Packages.seaborn
    python3Packages.requests  # For AI documentation system
    python3Packages.urllib3   # Required by requests
    python3Packages.idna      # Required by requests
    python3Packages.charset-normalizer  # Character detection for requests
    python3Packages.certifi   # SSL certificates for requests
  ];
  
# NOTE: ollama service configuration removed from here to avoid duplicate
# service definition. Service is configured in hosts/server/config.nix
# This prevents NixOS evaluation errors from conflicting service definitions.
  
  # Create AI workspace directories
  # AI services directories now created by modules/filesystem/business-directories.nix
  
  # Ensure AI scripts directory exists and scripts are deployed
  environment.etc = {
    "nixos/scripts/ai-docs-wrapper.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Wrapper for AI documentation generator to ensure proper Python environment
        
        export PYTHONPATH="/run/current-system/sw/lib/python3.13/site-packages:$PYTHONPATH"
        /run/current-system/sw/bin/python3 /etc/nixos/scripts/ai-narrative-docs.py "$@"
      '';
      mode = "0755";
    };
  };
  
  # AI model management service
  systemd.services.ai-model-setup = {
    description = "Download and setup AI models for business intelligence";
    serviceConfig = {
      Type = "oneshot";
      User = "eric";
      ExecStart = pkgs.writeShellScript "setup-ai-models" ''
        # Wait for ollama to be ready
        sleep 10
        
        # Download business-focused models (these are lightweight)
        ${pkgs.ollama}/bin/ollama pull llama3.2:3b  # Fast, efficient model
        ${pkgs.ollama}/bin/ollama pull nomic-embed-text  # For embeddings/RAG
        
        echo "AI models ready for business intelligence"
      '';
    };
    wantedBy = [ "multi-user.target" ];
    after = [ "ollama.service" ];
  };

  # HARDENED: Post-rebuild AI documentation service with locking
  systemd.services.post-rebuild-ai-docs = {
    description = "AI documentation processing after successful NixOS rebuild (HARDENED)";
    serviceConfig = {
      Type = "oneshot";
      User = "eric";
      WorkingDirectory = "/etc/nixos";
      ExecStart = pkgs.writeShellScript "post-rebuild-ai-docs-hardened" ''
        set -e
        
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        LOGFILE="/etc/nixos/docs/ai-doc-generation.log"
        LOCKFILE="/tmp/ai_docs_rebuild.lock"
        
        echo "🤖 Starting hardened post-rebuild AI documentation processing..."
        echo "$TIMESTAMP: Starting post-rebuild AI documentation (HARDENED)" >> "$LOGFILE"
        
        # HARDENING: Process locking to prevent drift between commits
        if [ -f "$LOCKFILE" ]; then
            EXISTING_PID=$(cat "$LOCKFILE" 2>/dev/null || echo "unknown")
            if kill -0 "$EXISTING_PID" 2>/dev/null; then
                echo "⏳ Another AI documentation process is running (PID: $EXISTING_PID)"
                echo "$TIMESTAMP: Skipped - another AI process running (PID: $EXISTING_PID)" >> "$LOGFILE"
                
                # Send notification about skipped processing
                curl -s -H "Title: ⏳ AI Docs Queued" \
                     -d "AI documentation skipped - another process running. Will retry on next rebuild." \
                     https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
                exit 0
            else
                echo "🧹 Removing stale lock file (PID $EXISTING_PID not running)"
                rm -f "$LOCKFILE"
            fi
        fi
        
        # Create lock with current PID
        echo $$ > "$LOCKFILE"
        trap 'rm -f "$LOCKFILE"' EXIT INT TERM
        
        # Check if there are uncommitted changes to process
        if [ -f "/etc/nixos/docs/SYSTEM_CHANGELOG.md" ]; then
          echo "📝 Processing system changes for AI documentation..."
          
          # HARDENING: Capture current commit for accurate processing
          CURRENT_COMMIT=$(git rev-parse HEAD)
          echo "📍 Processing changes for commit: $CURRENT_COMMIT"
          
          # Run AI documentation with timeout (5 minutes max)
          if timeout 300 bash /etc/nixos/scripts/ai-docs-wrapper.sh >> "$LOGFILE" 2>&1; then
            echo "✅ AI documentation generation complete!"
            echo "$TIMESTAMP: AI documentation generation successful for $CURRENT_COMMIT" >> "$LOGFILE"
            
            # Auto-commit documentation updates if any were made
            if ! git diff --quiet docs/; then
              echo "📚 Auto-committing documentation updates..."
              git add docs/
              git commit -m "🤖 Auto-update documentation via AI analysis (post-rebuild)

Generated after successful NixOS rebuild
Timestamp: $TIMESTAMP
Source commit: $CURRENT_COMMIT"
              
              # Send success notification with commit info
              curl -s -H "Title: 📚 NixOS Docs Updated" \
                   -d "AI documentation updated after successful rebuild at $TIMESTAMP (commit: ''${CURRENT_COMMIT:0:8})" \
                   https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
            else
              echo "📄 No documentation changes to commit"
              # Send notification about no changes
              curl -s -H "Title: 📄 AI Docs Checked" \
                   -d "AI processing complete - no documentation changes needed for commit ''${CURRENT_COMMIT:0:8}" \
                   https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
            fi
          else
            echo "⚠️ AI documentation generation failed - check $LOGFILE"
            echo "$TIMESTAMP: AI documentation generation failed for $CURRENT_COMMIT" >> "$LOGFILE"
            
            # Send error notification with commit info
            curl -s -H "Title: ❌ NixOS AI Docs Failed" -H "Priority: high" \
                 -d "AI documentation failed after rebuild at $TIMESTAMP (commit: ''${CURRENT_COMMIT:0:8})" \
                 https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
          fi
        else
          echo "📄 No changelog file found, skipping AI documentation"
          echo "$TIMESTAMP: Skipped - no changelog found" >> "$LOGFILE"
        fi
        
        echo "✅ Hardened post-rebuild AI documentation processing complete!"
        echo "$TIMESTAMP: Processing complete for $CURRENT_COMMIT" >> "$LOGFILE"
      '';
    };
    # This service is manually triggered, not automatically started
  };

  # UPDATED: Lightweight commit logging setup (no AI processing)
  systemd.services.ai-docs-setup = {
    description = "Setup lightweight git hooks for commit logging";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "setup-git-hooks" ''
        # Ensure git hooks directory exists
        mkdir -p /etc/nixos/.git/hooks
        
        # Install lightweight hook that only logs commits (no AI processing)
        cat > /etc/nixos/.git/hooks/post-commit << 'EOF'
#!/usr/bin/env bash
# Git Post-Commit Hook - Lightweight commit logging only
# AI processing now happens AFTER successful rebuilds, not on commits

COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "📝 Logging commit: $COMMIT_HASH"

# Skip AI-generated commits from logging
if echo "$COMMIT_MSG" | grep -q -E "(🤖 Auto-update|📚 Auto-committing|AI-generated|ai-docs-update)"; then
    echo "🔄 Skipping AI-generated commit log"
    exit 0
fi

# Ensure changelog directory exists  
mkdir -p /etc/nixos/docs

# Append to structured changelog (for AI processing later)
echo "
## Commit: $COMMIT_HASH
**Date:** $TIMESTAMP
**Message:** $COMMIT_MSG

\`\`\`diff
$(git show --no-merges --format="" $COMMIT_HASH)
\`\`\`

---
" >> /etc/nixos/docs/SYSTEM_CHANGELOG.md

echo "✅ Commit logged. AI processing will happen after successful rebuild."
EOF
        
        # Make hook executable
        chmod +x /etc/nixos/.git/hooks/post-commit
        
        # Create AI log file
        touch /etc/nixos/docs/ai-doc-generation.log
        chown eric:users /etc/nixos/docs/ai-doc-generation.log 2>/dev/null || true
        
        echo "Lightweight git hooks installed - AI processing separated from commits"
      '';
    };
    wantedBy = [ "multi-user.target" ];
  };

  # HARDENED: Enhanced grebuild function with git push error handling
  environment.etc."nixos/scripts/grebuild.sh" = {
    text = ''
      #!/usr/bin/env bash
      # HARDENED Enhanced grebuild function - Fast git workflow + rebuild, then AI processing
      # HARDENED: Git push error handling with notifications
      
      set -e
      
      if [ $# -eq 0 ]; then
          echo "Usage: grebuild \"commit message\""
          exit 1
      fi
      
      COMMIT_MESSAGE="$1"
      TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
      
      echo "🚀 Starting hardened grebuild workflow..."
      echo "📝 Commit message: $COMMIT_MESSAGE"
      
      # Step 1: Git operations (fast)
      echo "📦 Adding changes to git..."
      sudo git add .
      
      echo "💾 Committing changes..."
      sudo git commit -m "$COMMIT_MESSAGE"
      
      # Capture commit hash for notifications
      COMMIT_HASH=$(git rev-parse HEAD)
      SHORT_HASH="''${COMMIT_HASH:0:8}"
      
      # Step 2: Test rebuild first (safety check)
      echo "🧪 Testing NixOS configuration..."
      if sudo nixos-rebuild test --flake .#hwc-server; then
          echo "✅ Test successful!"
          
          # Step 3: Apply rebuild
          echo "🔄 Applying NixOS rebuild..."
          if sudo nixos-rebuild switch --flake .#hwc-server; then
              echo "✅ Rebuild successful!"
              
              # HARDENED Step 4: Git push with error handling
              echo "📤 Pushing to remote repository..."
              if sudo git push; then
                  echo "✅ Git push successful!"
                  PUSH_STATUS="✅ Pushed to remote"
              else
                  echo "⚠️ Warning: Git push failed!"
                  PUSH_STATUS="⚠️ Push failed - local changes only"
                  
                  # Send warning notification about push failure
                  curl -s -H "Title: ⚠️ Git Push Failed" -H "Priority: default" \
                       -d "NixOS rebuild succeeded but git push failed. Changes are local only. Commit: $SHORT_HASH" \
                       https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
              fi
              
              # Step 5: Trigger AI documentation (non-blocking)
              echo "🤖 Triggering AI documentation processing..."
              sudo systemctl start post-rebuild-ai-docs &
              
              # Send completion notification with push status
              curl -s -H "Title: ✅ NixOS Rebuild Complete" \
                   -d "Successfully rebuilt and deployed: $COMMIT_MESSAGE ($SHORT_HASH)
                   
$PUSH_STATUS
AI documentation processing started..." \
                   https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
              
              echo "🎉 Grebuild complete! AI documentation running in background."
              echo "📱 You'll receive a notification when AI docs are updated."
              echo "📍 Commit: $SHORT_HASH"
              echo "📤 Push status: $PUSH_STATUS"
              
          else
              echo "❌ Rebuild failed!"
              
              # Send failure notification
              curl -s -H "Title: ❌ NixOS Rebuild Failed" -H "Priority: urgent" \
                   -d "NixOS rebuild failed for commit: $COMMIT_MESSAGE ($SHORT_HASH). Check system logs." \
                   https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
              
              exit 1
          fi
      else
          echo "❌ Test failed! Not proceeding with rebuild."
          
          # Send test failure notification  
          curl -s -H "Title: ❌ NixOS Test Failed" -H "Priority: high" \
               -d "NixOS configuration test failed for: $COMMIT_MESSAGE ($SHORT_HASH). Changes not applied." \
               https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
          
          exit 1
      fi
    '';
    mode = "0755";
  };
  
  # Create grebuild function alias
  programs.bash.shellInit = ''
    # Enhanced grebuild function (HARDENED)
    grebuild() {
        bash /etc/nixos/scripts/grebuild.sh "$@"
    }
    export -f grebuild
  '';
}