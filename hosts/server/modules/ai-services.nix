# AI Services Configuration
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

  # AI documentation system setup service
  systemd.services.ai-docs-setup = {
    description = "Setup AI documentation system components";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "setup-ai-docs" ''
        # Ensure git hooks directory exists
        mkdir -p /etc/nixos/.git/hooks
        
        # Install git post-commit hook
        cat > /etc/nixos/.git/hooks/post-commit << 'EOF'
#!/usr/bin/env bash
# Git Post-Commit Hook for AI Documentation System
# Captures commit diffs and triggers AI analysis

COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "📝 Capturing commit for AI documentation system..."

# Ensure changelog directory exists
mkdir -p /etc/nixos/docs

# Append to structured changelog
echo "
## Commit: $COMMIT_HASH
**Date:** $TIMESTAMP
**Message:** $COMMIT_MSG

\`\`\`diff
$(git show --no-merges --format="" $COMMIT_HASH)
\`\`\`

---
" >> /etc/nixos/docs/SYSTEM_CHANGELOG.md

echo "🤖 Triggering AI documentation generation..."

# Run AI documentation generator
bash /etc/nixos/scripts/ai-docs-wrapper.sh 2>&1 | tee -a /etc/nixos/docs/ai-doc-generation.log

# Check if AI generation was successful
if [ $? -eq 0 ]; then
    echo "✅ AI documentation generation complete!"
    
    # Auto-commit documentation updates if any were made
    if git diff --quiet docs/; then
        echo "📄 No documentation changes to commit"
    else
        echo "📚 Auto-committing documentation updates..."
        git add docs/
        git commit -m "🤖 Auto-update documentation via AI analysis

Generated from commit: $COMMIT_HASH
Timestamp: $TIMESTAMP"
    fi
else
    echo "⚠️ AI documentation generation failed - check ai-doc-generation.log"
fi

echo "✅ Post-commit processing complete!"
EOF
        
        # Make hook executable
        chmod +x /etc/nixos/.git/hooks/post-commit
        
        # Create AI log file
        touch /etc/nixos/docs/ai-doc-generation.log
        chown eric:users /etc/nixos/docs/ai-doc-generation.log
        
        echo "AI documentation system components installed"
      '';
    };
    wantedBy = [ "multi-user.target" ];
  };
}
