# modules/filesystem/security-directories.nix
# Consolidated security and secrets directory structure
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # SECURITY AND SECRETS DIRECTORIES
  ####################################################################
  systemd.tmpfiles.rules = [
    ####################################################################
    # SECRETS MANAGEMENT (Root-owned secure storage)
    ####################################################################
    # Main secrets directory (restricted access)
    "d /etc/secrets 0750 root root -"
    
    # Secrets organization by type
    "d /etc/secrets/api-keys 0750 root root -"          # API keys and tokens
    "d /etc/secrets/certificates 0750 root root -"      # SSL certificates and keys
    "d /etc/secrets/ssh 0750 root root -"               # SSH keys and configuration
    
    ####################################################################
    # TAILSCALE CERTIFICATE MANAGEMENT
    ####################################################################
    # Tailscale certificate directories
    "d /var/lib/tailscale 0755 root root -"
    "d /var/lib/tailscale/certs 0755 root root -"
    
    # Certificate file permissions for Caddy access
    # Note: These Z rules set permissions on existing files
    "Z /var/lib/tailscale/certs/heartwood.ocelot-wahoo.ts.net.crt 0644 root caddy -"
    "Z /var/lib/tailscale/certs/heartwood.ocelot-wahoo.ts.net.key 0640 root caddy -"
  ];
  
  ####################################################################
  # SECURITY DIRECTORIES DOCUMENTATION
  ####################################################################
  environment.etc."security-directories-help.md".text = ''
    # Security Directory Structure Guide
    
    ## Secrets Management (/etc/secrets/)
    
    This directory contains sensitive configuration files with restricted access.
    
    ### 🔐 Access Control
    - **Ownership**: `root:root` (system-level security)
    - **Permissions**: `0750` (read/write for root, read for root group only)
    - **Purpose**: Maximum security for sensitive data
    
    ### 📁 Directory Organization
    
    #### /etc/secrets/api-keys/
    - **Purpose**: API keys and authentication tokens
    - **Examples**: 
      - `openai.key` - OpenAI API key
      - `jobtread.json` - JobTread API credentials
      - Service-specific API tokens
    
    #### /etc/secrets/certificates/
    - **Purpose**: SSL certificates and private keys
    - **Examples**:
      - `domain.crt` - SSL certificate
      - `domain.key` - Private key
      - CA certificates for internal services
    
    #### /etc/secrets/ssh/
    - **Purpose**: SSH keys and configuration
    - **Examples**:
      - `deploy_key` - Deployment SSH key
      - Service-specific SSH configurations
    
    ## Certificate Management (/var/lib/tailscale/)
    
    ### 🌐 Tailscale Integration
    - **Purpose**: Automated certificate management for secure networking
    - **Provider**: Tailscale's certificate authority
    - **Domain**: heartwood.ocelot-wahoo.ts.net
    
    ### 📜 Certificate Files
    
    #### Certificate File (*.crt)
    - **Path**: `/var/lib/tailscale/certs/heartwood.ocelot-wahoo.ts.net.crt`
    - **Permissions**: `0644 root caddy` (readable by Caddy service)
    - **Purpose**: Public certificate for TLS termination
    
    #### Private Key (*.key)
    - **Path**: `/var/lib/tailscale/certs/heartwood.ocelot-wahoo.ts.net.key`
    - **Permissions**: `0640 root caddy` (secure access for Caddy only)
    - **Purpose**: Private key for TLS termination
    
    ## Security Best Practices
    
    ### 🔒 File Security
    1. **Never commit secrets to git repositories**
    2. **Use proper file permissions** (600 for private keys, 644 for certificates)
    3. **Regular rotation** of API keys and certificates
    4. **Backup encryption** for all sensitive data
    
    ### 🚀 Deployment Security
    1. **Use deployment scripts** for secret placement
    2. **Verify permissions** after deployment
    3. **Audit access logs** regularly
    4. **Implement secret scanning** in CI/CD pipelines
    
    ### 🔄 SOPS Integration
    
    This system integrates with SOPS (Secrets OPerationS) for encrypted secret management:
    
    #### SOPS-Managed Secrets
    - Database passwords in `/etc/nixos/secrets/database.yaml`
    - Admin credentials in `/etc/nixos/secrets/admin.yaml`
    - Surveillance system secrets in `/etc/nixos/secrets/surveillance.yaml`
    
    #### Age Encryption
    - Private keys deployed to `/etc/sops/age/keys.txt`
    - Host-specific encryption for laptop and server
    - Automated secret deployment via NixOS service
    
    ## Backup and Recovery
    
    ### 🗄️ Backup Strategy
    - **Encrypted backups** of all secret directories
    - **Multiple backup locations** (local and remote)
    - **Recovery testing** procedures
    
    ### 📋 Recovery Procedures
    1. **Secret restoration** from encrypted backups
    2. **Certificate regeneration** via Tailscale
    3. **API key rotation** and service updates
    4. **Permission verification** after restoration
    
    ## Monitoring and Auditing
    
    ### 📊 Security Monitoring
    - File access logging for sensitive directories
    - Certificate expiration monitoring
    - Unauthorized access detection
    - Regular security audits
    
    ### 🔍 Compliance
    - Regular permission audits
    - Secret rotation schedules
    - Access log reviews
    - Security policy compliance checks
    
    ## Integration Points
    
    ### 🔗 Service Integration
    - **Caddy**: TLS certificate access for web services
    - **SOPS**: Encrypted secret management
    - **Tailscale**: Automated certificate provisioning
    - **Business services**: Secure API key access
    
    ### 🛠️ Management Tools
    - `secrets-init`: Initialize secret directory structure
    - `secrets-backup`: Create encrypted backups
    - SOPS commands for secret editing
    - Certificate monitoring scripts
  '';
}