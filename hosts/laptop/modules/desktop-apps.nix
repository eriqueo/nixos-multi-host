# hosts/laptop/modules/desktop-apps.nix
# Desktop applications for laptop GUI environment
{ config, pkgs, lib, ... }:

{
  # Browser configurations using Home Manager program modules
  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;
  };

  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
  };




 # /path/to/your/desktop-apps.nix


   # Enhanced Dynamic Blender Configuration
   hwc.blender = {
     enable = true;

     # --- Basic Paths (auto-created if they don't exist) ---
     mediaRoot = "/home/eric/05-media/blender";
     renderOutputDir = "/home/eric/05-media/blender/renders";

     # --- Dynamic Addon Management ---
     autoDiscoverAddons = true;  # This is the key feature!

     # Only specify built-in Blender addons or ones with special names
     enableAddons = [
       "io_import_images_as_planes"  # Built-in addon
       "node_wrangler"               # Built-in addon
       "mesh_extra_objects"          # Built-in addon
     ];

     # Exclude any problematic addons from auto-enablement
     excludeAddons = [
       # "some_broken_addon"  # Uncomment if you have problematic addons
     ];

     # --- Extensions & ZIP Management ---
     extensionsRoot = "/home/eric/05-media/blender/extensions";
     autoInstallAllZipsInExtensionsRoot = true;  # Auto-install all ZIPs

     # --- Performance Optimization ---
     optimizePerformance = true;
     memoryCacheLimit = 4096;  # Adjust based on your RAM
     computeDeviceType = "CUDA";  # Change to "OPENCL" for AMD, "OPTIX" for RTX cards

     # --- User Interface Preferences ---
     showSplashScreen = false;
     enterEditModeOnAdd = true;
     autoSave = true;
     autoSaveTime = 2;  # minutes

     # --- Enhanced Deck Tools (with dynamic script discovery) ---
     deckTools = {
       enable = true;
       # The addon will automatically discover scripts in mediaRoot/scripts/
       # You can still specify paths for specific scripts if needed:
       # cutlistXlsx = "/path/to/your/cutlist.xlsx";
     };

     # --- Window Manager Rules ---
     addWindowRules = true;
     addAltF4 = true;
   };






  # Desktop applications
  home.packages = with pkgs; [
    # Communication
    electron-mail       # Email client

    # File management
    xfce.thunar        # File manager
    gvfs               # Virtual file system support
    xfce.tumbler       # Thumbnail generator
    file-roller        # Archive manager
    imv                # Image viewer
    samba
    # Office and documents
    libreoffice        # Office suite
    zathura            # PDF viewer
    kdePackages.okular # Alternative PDF viewer

    # System utilities
    blueman            # Bluetooth manager
    timeshift          # System backup
    udiskie            # Automatic USB mounting
    redshift           # Blue light filter
    pavucontrol        # Audio control

    # Security tools
    gnupg              # GPG encryption
    gnupg-pkcs11-scd   # Smart card support
    pinentry-gtk2      # GPG PIN entry

    # Fonts
    noto-fonts         # Google Noto fonts
    noto-fonts-emoji   # Emoji support
  ];

  # Application-specific configurations

  # LibreOffice dark theme configuration
  home.file.".config/libreoffice/4/user/config/registrymodifications.xcu".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <item oor:path="/org.openoffice.Office.Common/VCL">
        <prop oor:name="PreferredAppearance" oor:op="fuse">
          <value>1</value>
        </prop>
      </item>
    </oor:items>
  '';

  # Enable XDG desktop integration
  xdg.enable = true;
}
