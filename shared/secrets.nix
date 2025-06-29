# modules/secrets/secrets.nix
{ lib, config, pkgs, ... }:

let
  # Import script utilities
  scripts = import ../lib/scripts.nix { inherit lib pkgs config; };
in

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
  # Import path utilities
  imports = [
    ../modules/paths
  ];

  # Script to help with secrets management using best practices
  environment.systemPackages = with pkgs; [
    # Secrets initialization helper
    (scripts.mkInfoScript "secrets-init" {
      title = "🔐 Heartwood Craft Secrets Management";
      sections = {
        "Secrets Configuration" = ''
          echo "  Secrets directory: $SECRETS_DIR"
          echo "  Template file: $SECRETS_DIR/template.env"
          echo "  SOPS age key: $HEARTWOOD_SOPS_AGE_KEY"
        '';
        
        "Adding Secrets" = ''
          echo "  1. sudo ${pkgs.coreutils}/bin/cp $SECRETS_DIR/template.env $SECRETS_DIR/production.env"
          echo "  2. sudo ${pkgs.nano}/bin/nano $SECRETS_DIR/production.env"
          echo "  3. Update with real values"
          echo "  4. sudo ${pkgs.coreutils}/bin/chmod 600 $SECRETS_DIR/production.env"
        '';
        
        "Current Structure" = ''
          if [[ -d "$SECRETS_DIR" ]]; then
            echo "  Current secrets structure:"
            ${pkgs.sudo}/bin/sudo ${pkgs.findutils}/bin/find "$SECRETS_DIR" -type f -exec ${pkgs.coreutils}/bin/ls -la {} \; 2>/dev/null || echo "  No secrets found or access denied"
          else
            log_warning "Secrets directory not found: $SECRETS_DIR"
          fi
        '';
      };
    })

    # Encrypted secrets backup with proper error handling
    (scripts.mkScriptWithEnsureDirs "secrets-backup" 
      [ config.heartwood.paths.backupRoot ] ''
      BACKUP_DIR="$BACKUP_ROOT/secrets"
      DATE=$(${pkgs.coreutils}/bin/date +%Y%m%d_%H%M%S)
      
      log_info "Backing up secrets (encrypted)..."
      ensure_directory "$BACKUP_DIR"
      
      # Verify secrets directory exists
      if [[ ! -d "$SECRETS_DIR" ]]; then
        log_error "Secrets directory not found: $SECRETS_DIR"
        exit 1
      fi
      
      # Create encrypted backup of secrets directory
      if ${pkgs.gnutar}/bin/tar -czf - "$SECRETS_DIR" | \
         ${pkgs.gnupg}/bin/gpg --symmetric --cipher-algo AES256 > \
         "$BACKUP_DIR/secrets_$DATE.tar.gz.gpg"; then
        
        log_success "Secrets backed up to: $BACKUP_DIR/secrets_$DATE.tar.gz.gpg"
        log_warning "Remember the passphrase for decryption!"
        
        # Cleanup old backups (keep last 30 days)
        ${pkgs.findutils}/bin/find "$BACKUP_DIR" -name "secrets_*.tar.gz.gpg" -mtime +30 -delete 2>/dev/null || true
        
      else
        log_error "Failed to create encrypted backup"
        exit 1
      fi
    '')
  ];
}
