{ config, pkgs, ... }:

{
  # Business API packages
  environment.systemPackages = with pkgs; [
    # FastAPI and web framework tools
    python3Packages.fastapi
    python3Packages.uvicorn
    python3Packages.pydantic
    python3Packages.python-multipart
    
    # Database and data processing
    python3Packages.sqlalchemy
    python3Packages.alembic  # Database migrations
    python3Packages.psycopg2
    python3Packages.asyncpg
    python3Packages.pandas
    
    # Business integrations
    python3Packages.httpx  # For JobTread API
    python3Packages.requests
    python3Packages.python-dotenv
    
    # Document processing and OCR
    python3Packages.pillow
    python3Packages.opencv4
    python3Packages.pytesseract
    python3Packages.pdf2image
    
    # Data visualization
    python3Packages.streamlit
    python3Packages.plotly
    python3Packages.altair
  ];
  
  # Create business API directories
  # Business API directories now created by modules/filesystem/business-directories.nix
  
  # Business API development environment setup
  environment.etc."business/setup-dev-env.sh" = {
    text = ''
      #!/bin/bash
      
      echo "Setting up Heartwood Craft business development environment..."
      
      # Create Python virtual environment for business API
      cd /opt/business/api
      python3 -m venv venv
      source venv/bin/activate
      
      # Create requirements.txt if it doesn't exist
      if [ ! -f requirements.txt ]; then
        cat > requirements.txt << EOF
      fastapi==0.104.1
      uvicorn[standard]==0.24.0
      sqlalchemy==2.0.23
      alembic==1.13.1
      psycopg2-binary==2.9.9
      asyncpg==0.29.0
      pandas==2.1.4
      pydantic==2.5.0
      python-multipart==0.0.6
      python-dotenv==1.0.0
      httpx==0.25.2
      requests==2.31.0
      pillow==10.1.0
      opencv-python==4.8.1.78
      pytesseract==0.3.10
      pdf2image==1.16.3
      streamlit==1.28.1
      plotly==5.17.0
      altair==5.1.2
      redis==5.0.1
      chromadb==0.4.18
      sentence-transformers==2.2.2
      langchain==0.1.0
      openai==1.3.0
      EOF
      fi
      
      # Install requirements
      pip install -r requirements.txt
      
      echo "Business development environment ready!"
      echo "Database: postgresql://business_user:secure_password_change_me@localhost:5432/heartwood_business"
      echo "Redis: redis://localhost:6379/0"
      echo "Ollama: http://localhost:11434"
      echo "API will run on: http://localhost:8000"
      echo "Dashboard will run on: http://localhost:8501"
    '';
    mode = "0755";
  };
  
  # Business API systemd service (for production)
  systemd.services.business-api = {
    description = "Heartwood Craft Business API";
    after = [ "postgresql.service" "redis-business.service" "ollama.service" ];
    wants = [ "postgresql.service" "redis-business.service" "ollama.service" ];
    serviceConfig = {
      Type = "simple";
      User = "eric";
      WorkingDirectory = "/opt/business/api";
      ExecStart = "${pkgs.python3Packages.uvicorn}/bin/uvicorn main:app --host 0.0.0.0 --port 8000";
      Restart = "always";
      RestartSec = "10";
    };
    # Don't auto-start - we'll start manually during development
    wantedBy = [ ];
  };
}
