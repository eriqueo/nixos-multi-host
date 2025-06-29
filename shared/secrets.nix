# modules/secrets/secrets.nix
{ lib, config, pkgs, ... }:

{
  # Secrets directory structure now created by modules/filesystem/security-directories.nix

  # Placeholder for secret files - create these manually or via deployment scripts
  environment.etc = {
    "secrets/README.md" = {
      text = ''
        # Secrets Directory

        This directory contains sensitive configuration files.
        
        ## Structure:
        - api-keys/: API keys and tokens
        - certificates/: SSL certificates and keys
        - ssh/: SSH keys and configuration
        
        ## Security:
        - Files in this directory should be mode 600 or 400
        - Never commit actual secrets to git
        - Use deployment scripts or manual placement for real secrets
        
        ## Example files to create:
        - api-keys/openai.key
        - api-keys/jobtread.json
        - certificates/domain.crt
        - certificates/domain.key
        - ssh/deploy_key
      '';
      mode = "0644";
    };
    
    "secrets/template.env" = {
      text = ''
        # Template for environment variables
        # Copy to actual .env file and fill in real values
        
        OPENAI_API_KEY=your_openai_api_key_here
        JOBTREAD_API_KEY=your_jobtread_api_key_here
        DATABASE_PASSWORD=your_secure_database_password_here
        SMTP_PASSWORD=your_email_password_here
      '';
      mode = "0600";
    };
  };
  # User configuration moved to modules/users/eric.nix
  # Script to help with secrets management
  environment.systemPackages = with pkgs; [
    (writeScriptBin "secrets-init" ''
      #!/bin/bash
      echo "🔐 Heartwood Craft Secrets Management"
      echo "===================================="
      echo
      echo "Secrets directory: /etc/secrets"
      echo "Template file: /etc/secrets/template.env"
      echo
      echo "To add secrets:"
      echo "1. sudo cp /etc/secrets/template.env /etc/secrets/production.env"
      echo "2. sudo nano /etc/secrets/production.env"
      echo "3. Update with real values"
      echo "4. sudo chmod 600 /etc/secrets/production.env"
      echo
      echo "Current secrets structure:"
      sudo find /etc/secrets -type f -exec ls -la {} \;
    '')

    (writeScriptBin "secrets-backup" ''
      #!/bin/bash
      BACKUP_DIR="/opt/business/backups/secrets"
      DATE=$(date +%Y%m%d_%H%M%S)
      
      echo "🔐 Backing up secrets (encrypted)..."
      sudo mkdir -p "$BACKUP_DIR"
      
      # Create encrypted backup of secrets directory
      sudo tar -czf - /etc/secrets | gpg --symmetric --cipher-algo AES256 > "$BACKUP_DIR/secrets_$DATE.tar.gz.gpg"
      
      echo "✅ Secrets backed up to: $BACKUP_DIR/secrets_$DATE.tar.gz.gpg"
      echo "⚠️  Remember the passphrase for decryption!"
    '')
  ];
}
