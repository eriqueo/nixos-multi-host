{ config, pkgs, ... }:

{
  # AI and ML packages
  environment.systemPackages = with pkgs; [
    # AI/ML tools
    ollama
    python3Packages.torch
    python3Packages.transformers
    python3Packages.sentence-transformers
    python3Packages.chromadb  # Vector database for RAG
    python3Packages.langchain
    python3Packages.openai  # For API compatibility
    
    # Additional ML libraries
    python3Packages.numpy
    python3Packages.scikit-learn
    python3Packages.matplotlib
    python3Packages.seaborn
  ];
  
services.ollama = {
  enable = true;
  acceleration = "cuda";  # Enable CUDA acceleration
  host = "127.0.0.1";
  port = 11434;
  # Move models to hot storage for faster loading
  home = "/mnt/hot/ai";
};
  
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
