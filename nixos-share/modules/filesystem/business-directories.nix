# modules/filesystem/business-directories.nix
# Consolidated business application directory structure
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # BUSINESS APPLICATION DIRECTORIES
  ####################################################################
  systemd.tmpfiles.rules = [
    # Main business directory
    "d /opt/business 0755 eric users -"
    
    # Business API structure
    "d /opt/business/api 0755 eric users -"
    "d /opt/business/api/app 0755 eric users -"
    "d /opt/business/api/models 0755 eric users -"
    "d /opt/business/api/routes 0755 eric users -"
    "d /opt/business/api/services 0755 eric users -"
    
    # Business dashboard and configuration
    "d /opt/business/dashboard 0755 eric users -"
    "d /opt/business/config 0755 eric users -"
    
    # Document processing and storage
    "d /opt/business/uploads 0755 eric users -"         # Incoming documents
    "d /opt/business/receipts 0755 eric users -"        # Receipt processing
    "d /opt/business/processed 0755 eric users -"       # Processed documents
    
    # Business data backups
    "d /opt/business/backups 0755 eric users -"
    "d /opt/business/backups/secrets 0755 eric users -" # Encrypted secret backups
    
    ####################################################################
    # AI/ML BUSINESS INTELLIGENCE DIRECTORIES
    ####################################################################
    # Main AI directory
    "d /opt/ai 0755 eric users -"
    
    # AI model storage and management
    "d /opt/ai/models 0755 eric users -"                # AI model files
    "d /opt/ai/context-snapshots 0755 eric users -"     # Context state backups
    "d /opt/ai/document-embeddings 0755 eric users -"   # Vector embeddings
    "d /opt/ai/business-rag 0755 eric users -"          # RAG system data
    
    ####################################################################
    # ADHD PRODUCTIVITY TOOLS DIRECTORIES
    ####################################################################
    # Main ADHD tools directory
    "d /opt/adhd-tools 0755 eric users -"
    
    # ADHD productivity tracking
    "d /opt/adhd-tools/context-snapshots 0755 eric users -"  # Work context saves
    "d /opt/adhd-tools/focus-logs 0755 eric users -"         # Focus session data
    "d /opt/adhd-tools/energy-tracking 0755 eric users -"    # Energy level logs
    "d /opt/adhd-tools/scripts 0755 eric users -"            # Automation scripts
  ];
  
  ####################################################################
  # BUSINESS DIRECTORIES DOCUMENTATION
  ####################################################################
  environment.etc."business-directories-help.md".text = ''
    # Business Directory Structure Guide
    
    ## Business Intelligence Platform (/opt/business/)
    
    ### API Structure (/opt/business/api/)
    - **app/**: Main application code
    - **models/**: Data models and schemas
    - **routes/**: API endpoint definitions
    - **services/**: Business logic services
    
    ### Document Processing Pipeline
    1. **uploads/**: Raw incoming documents
    2. **receipts/**: Receipt-specific processing
    3. **processed/**: OCR and analyzed documents
    4. **backups/**: Encrypted backups of all data
    
    ### Configuration Management
    - **config/**: Application configuration files
    - **dashboard/**: Business dashboard components
    
    ## AI/ML Intelligence (/opt/ai/)
    
    ### Model Management
    - **models/**: AI model files and weights
    - **context-snapshots/**: Saved conversation contexts
    - **document-embeddings/**: Vector database for documents
    - **business-rag/**: RAG (Retrieval Augmented Generation) data
    
    ## ADHD Productivity Tools (/opt/adhd-tools/)
    
    ### Productivity Tracking
    - **context-snapshots/**: Work session state saves
    - **focus-logs/**: Focus session duration and quality
    - **energy-tracking/**: Daily energy level monitoring
    - **scripts/**: Automation and workflow scripts
    
    ## Integration Points
    
    ### Business API Integration
    - Connects to PostgreSQL database for document metadata
    - Uses Redis for session and cache management
    - Integrates with AI services for document analysis
    
    ### AI Service Integration
    - Ollama for local AI model serving
    - Vector database for semantic search
    - RAG pipeline for business document queries
    
    ### ADHD Tool Integration
    - Context-aware automation based on energy levels
    - Focus session triggers for productivity workflows
    - Integration with business workflows for seamless transitions
    
    ## Security Considerations
    
    - All directories owned by 'eric users' for application access
    - Sensitive data encrypted before storage in backups/
    - AI models and embeddings stored locally for privacy
    - ADHD tracking data kept private and local
  '';
}