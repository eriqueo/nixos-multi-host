# lib/scripts.nix
# Script building utilities for Heartwood Craft modules
{ lib, pkgs, config ? {} }:

with lib;

let
  # Get paths from config, with fallbacks
  cfg = config.heartwood.paths or {};
  
  # Common script header with error handling and environment setup
  scriptHeader = ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Color output functions
    red() { echo -e "\033[0;31m$*\033[0m"; }
    green() { echo -e "\033[0;32m$*\033[0m"; }
    yellow() { echo -e "\033[1;33m$*\033[0m"; }
    blue() { echo -e "\033[0;34m$*\033[0m"; }
    
    # Logging functions
    log_info() { blue "[INFO] $*"; }
    log_success() { green "[SUCCESS] $*"; }
    log_warning() { yellow "[WARNING] $*"; }
    log_error() { red "[ERROR] $*"; }
    
    # Common utility functions
    check_command() {
      if ! command -v "$1" >/dev/null 2>&1; then
        log_error "Required command '$1' not found"
        exit 1
      fi
    }
    
    check_directory() {
      if [[ ! -d "$1" ]]; then
        log_error "Required directory '$1' not found"
        exit 1
      fi
    }
    
    ensure_directory() {
      if [[ ! -d "$1" ]]; then
        log_info "Creating directory: $1"
        ${pkgs.coreutils}/bin/mkdir -p "$1"
      fi
    }
    
    # Path variables from configuration with fallbacks
    export USER_HOME="${cfg.userHome or "/home/eric"}"
    export USER_TEMP="${cfg.userTempDir or "/home/eric/99-temp"}"
    export USER_SSH="${cfg.userSshDir or "/home/eric/.ssh"}"
    export USER_DEV="${cfg.userDevDir or "/home/eric/dev"}"
    export HOT_STORAGE="${cfg.hotStorage or "/mnt/hot"}"
    export COLD_STORAGE="${cfg.coldStorage or "/mnt/media"}"
    export BUSINESS_ROOT="${cfg.businessRoot or "/opt/business"}"
    export SURVEILLANCE_ROOT="${cfg.surveillanceRoot or "/opt/surveillance"}"
    export AI_ROOT="${cfg.aiRoot or "/opt/ai"}"
    export ADHD_TOOLS_ROOT="${cfg.adhdToolsRoot or "/opt/adhd-tools"}"
    export SECRETS_DIR="${cfg.secretsDir or "/etc/secrets"}"
    export NIXOS_CONFIG="${cfg.nixosConfigDir or "/etc/nixos"}"
    export BACKUP_ROOT="${cfg.backupRoot or "/opt/business/backups"}"
    export LOG_DIR="${cfg.logDir or "/var/log"}"
    export TEMP_DIR="${cfg.tempDir or "/tmp"}"
  '';

in rec {
  # Build a script with common utilities and error handling
  mkScript = name: script: pkgs.writeScriptBin name (scriptHeader + script);
  
  # Build a script that requires specific directories to exist
  mkScriptWithDirs = name: requiredDirs: script: 
    let
      dirChecks = concatMapStringsSep "\n" (dir: "check_directory \"${dir}\"") requiredDirs;
    in
    pkgs.writeScriptBin name (scriptHeader + dirChecks + "\n" + script);
  
  # Build a script that ensures specific directories exist
  mkScriptWithEnsureDirs = name: ensuredDirs: script:
    let
      dirEnsure = concatMapStringsSep "\n" (dir: "ensure_directory \"${dir}\"") ensuredDirs;
    in
    pkgs.writeScriptBin name (scriptHeader + dirEnsure + "\n" + script);
  
  # Build a script with specific package dependencies
  mkScriptWithDeps = name: deps: script:
    let
      depChecks = concatMapStringsSep "\n" (dep: 
        let pkgName = if isString dep then dep else dep.pname or dep.name;
        in "check_command \"${pkgName}\""
      ) deps;
      pathAdditions = concatMapStringsSep ":" (dep:
        if isString dep then ""
        else "${dep}/bin"
      ) (filter (dep: !isString dep) deps);
      pathExport = optionalString (pathAdditions != "") 
        "export PATH=\"${pathAdditions}:$PATH\"";
    in
    pkgs.writeScriptBin name (scriptHeader + pathExport + "\n" + depChecks + "\n" + script);
  
  # Common maintenance script pattern
  mkMaintenanceScript = name: { 
    description, 
    cleanupDirs ? [], 
    backupDirs ? [], 
    checkDirs ? [],
    customActions ? ""
  }: 
    let
      cleanupActions = concatMapStringsSep "\n" (dir: ''
        if [[ -d "${dir}" ]]; then
          log_info "Cleaning up ${dir}..."
          ${pkgs.findutils}/bin/find "${dir}" -type f -mtime +7 -delete 2>/dev/null || true
          ${pkgs.findutils}/bin/find "${dir}" -type d -empty -delete 2>/dev/null || true
        fi
      '') cleanupDirs;
      
      backupActions = concatMapStringsSep "\n" (dir: ''
        if [[ -d "${dir}" ]]; then
          log_info "Backing up ${dir}..."
          DATE=$(${pkgs.coreutils}/bin/date +%Y%m%d_%H%M%S)
          ${pkgs.gnutar}/bin/tar -czf "$BACKUP_ROOT/$(basename ${dir})_$DATE.tar.gz" -C "$(dirname ${dir})" "$(basename ${dir})"
        fi
      '') backupDirs;
      
      checkActions = concatMapStringsSep "\n" (dir: ''
        if [[ -d "${dir}" ]]; then
          log_success "✅ ${dir}"
        else
          log_error "❌ ${dir} (missing)"
        fi
      '') checkDirs;
      
    in
    mkScript name ''
      log_info "${description}"
      log_info "$(${pkgs.coreutils}/bin/echo "${description}" | ${pkgs.gnused}/bin/sed 's/./ /g')"
      echo
      
      ${optionalString (checkDirs != []) ''
        log_info "Directory Check:"
        ${checkActions}
        echo
      ''}
      
      ${optionalString (cleanupActions != "") ''
        log_info "Cleanup Operations:"
        ${cleanupActions}
        echo
      ''}
      
      ${optionalString (backupActions != "") ''
        log_info "Backup Operations:"
        ensure_directory "$BACKUP_ROOT"
        ${backupActions}
        echo
      ''}
      
      ${optionalString (customActions != "") ''
        log_info "Custom Actions:"
        ${customActions}
        echo
      ''}
      
      log_success "Maintenance completed successfully"
    '';
    
  # System information script pattern
  mkInfoScript = name: {
    title,
    sections ? {}
  }:
    let
      sectionOutput = concatStringsSep "\n\n" (mapAttrsToList (sectionTitle: sectionContent: ''
        log_info "${sectionTitle}:"
        ${sectionContent}
      '') sections);
    in
    mkScript name ''
      blue "${title}"
      blue "$(${pkgs.coreutils}/bin/echo "${title}" | ${pkgs.gnused}/bin/sed 's/./=/g')"
      echo
      
      ${sectionOutput}
    '';
}