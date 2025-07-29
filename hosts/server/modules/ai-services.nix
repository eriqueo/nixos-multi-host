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
  ];
  
# NOTE: ollama service configuration removed from here to avoid duplicate
# service definition. Service is configured in hosts/server/config.nix
# This prevents NixOS evaluation errors from conflicting service definitions.
  
  # Create AI workspace directories
  # AI services directories now created by modules/filesystem/business-directories.nix
  
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
}
