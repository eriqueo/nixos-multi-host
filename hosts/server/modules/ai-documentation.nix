# AI Documentation Services Configuration
# 
# UPDATED: Separated AI documentation from grebuild workflow
# - Lightweight post-commit hook for logging only
# - AI processing now triggered AFTER successful rebuilds
# - Prevents blocking grebuild function with slow AI processing
#
# NOTE: Heavy AI/ML packages commented out for faster initial builds.
# Uncomment these packages after initial system setup is complete:
#   - python3Packages.torch (~25 min build time)
#   - python3Packages.transformers (~15 min build time)
#   - python3Packages.sentence-transformers
#   - python3Packages.chromadb
#   - python3Packages.langchain
# 
# GPU acceleration and ollama service are kept enabled for Frigate integration.

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

  # NEW: Post-rebuild AI documentation service (separated from grebuild)
  systemd.services.post-rebuild-ai-docs = {
    description = "AI documentation processing after successful NixOS rebuild";
    serviceConfig = {
      Type = "oneshot";
      User = "eric";
      WorkingDirectory = "/etc/nixos";
      ExecStart = pkgs.writeShellScript "post-rebuild-ai-docs" ''
        set -e
        
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        LOGFILE="/etc/nixos/docs/ai-doc-generation.log"
        
        echo "🤖 Starting post-rebuild AI documentation processing..."
        echo "$TIMESTAMP: Starting post-rebuild AI documentation" >> "$LOGFILE"
        
        # Check if there are uncommitted changes to process
        if [ -f "/etc/nixos/docs/SYSTEM_CHANGELOG.md" ]; then
          echo "📝 Processing system changes for AI documentation..."
          
          # Run AI documentation with timeout (5 minutes max)
          if timeout 300 bash /etc/nixos/scripts/ai-docs-wrapper.sh >> "$LOGFILE" 2>&1; then
            echo "✅ AI documentation generation complete!"
            echo "$TIMESTAMP: AI documentation generation successful" >> "$LOGFILE"
            
            # Auto-commit documentation updates if any were made
            if ! git diff --quiet docs/; then
              echo "📚 Auto-committing documentation updates..."
              git add docs/
              git commit -m "🤖 Auto-update documentation via AI analysis (post-rebuild)

Generated after successful NixOS rebuild
Timestamp: $TIMESTAMP"
              
              # Send success notification
              curl -s -H "Title: 📚 NixOS Docs Updated" \
                   -d "AI documentation updated after successful rebuild at $TIMESTAMP" \
                   https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
            else
              echo "📄 No documentation changes to commit"
            fi
          else
            echo "⚠️ AI documentation generation failed - check $LOGFILE"
            echo "$TIMESTAMP: AI documentation generation failed" >> "$LOGFILE"
            
            # Send error notification
            curl -s -H "Title: ❌ NixOS AI Docs Failed" -H "Priority: high" \
                 -d "AI documentation failed after rebuild at $TIMESTAMP" \
                 https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
          fi
        else
          echo "📄 No changelog file found, skipping AI documentation"
        fi
        
        echo "✅ Post-rebuild AI documentation processing complete!"
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

  # Enhanced grebuild function that triggers AI docs after successful rebuild
  environment.etc."nixos/scripts/grebuild.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Enhanced grebuild function - Fast git workflow + rebuild, then AI processing
      
      set -e
      
      if [ $# -eq 0 ]; then
          echo "Usage: grebuild \"commit message\""
          exit 1
      fi
      
      COMMIT_MESSAGE="$1"
      TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
      
      echo "🚀 Starting grebuild workflow..."
      echo "📝 Commit message: $COMMIT_MESSAGE"
      
      # Step 1: Git operations (fast)
      echo "📦 Adding changes to git..."
      sudo git add .
      
      echo "💾 Committing changes..."
      sudo git commit -m "$COMMIT_MESSAGE"
      
      # Step 2: Test rebuild first (safety check)
      echo "🧪 Testing NixOS configuration..."
      if sudo nixos-rebuild test --flake .#hwc-server; then
          echo "✅ Test successful!"
          
          # Step 3: Apply rebuild
          echo "🔄 Applying NixOS rebuild..."
          if sudo nixos-rebuild switch --flake .#hwc-server; then
              echo "✅ Rebuild successful!"
              
              # Step 4: Push to remote
              echo "📤 Pushing to remote repository..."
              sudo git push
              
              # Step 5: Trigger AI documentation (non-blocking)
              echo "🤖 Triggering AI documentation processing..."
              sudo systemctl start post-rebuild-ai-docs &
              
              # Send completion notification
              curl -s -H "Title: ✅ NixOS Rebuild Complete" \
                   -d "Successfully rebuilt and deployed: $COMMIT_MESSAGE" \
                   https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
              
              echo "🎉 Grebuild complete! AI documentation running in background."
              echo "📱 You'll receive a notification when AI docs are updated."
              
          else
              echo "❌ Rebuild failed!"
              exit 1
          fi
      else
          echo "❌ Test failed! Not proceeding with rebuild."
          exit 1
      fi
    '';
    mode = "0755";
  };
  
  # Create grebuild function alias
  programs.bash.shellInit = ''
    # Enhanced grebuild function
    grebuild() {
        bash /etc/nixos/scripts/grebuild.sh "$@"
    }
    export -f grebuild
  '';
}