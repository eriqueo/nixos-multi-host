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

  # Terminal configuration
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "CaskaydiaCove Nerd Font";
      font_size = 16;
      enable_audio_bell = false;
      window_padding_width = 4;

      # Deep Nord/Gruvbox Material color scheme
      foreground = "#d4be98";
      background = "#282828";
      selection_foreground = "#282828";
      selection_background = "#7daea3";

      # Cursor
      cursor = "#d4be98";
      cursor_text_color = "#282828";

      # URL color
      url_color = "#7daea3";

      # Normal colors
      color0 = "#32302F";  # black
      color1 = "#ea6962";  # red
      color2 = "#a9b665";  # green
      color3 = "#d8a657";  # yellow
      color4 = "#7daea3";  # blue
      color5 = "#d3869b";  # magenta
      color6 = "#89b482";  # cyan
      color7 = "#d4be98";  # white

      # Bright colors
      color8 = "#45403d";   # bright black
      color9 = "#ea6962";   # bright red
      color10 = "#a9b665";  # bright green
      color11 = "#d8a657";  # bright yellow
      color12 = "#7daea3";  # bright blue
      color13 = "#d3869b";  # bright magenta
      color14 = "#89b482";  # bright cyan
      color15 = "#d4be98";  # bright white

      # Window styling to match Hyprland
      background_opacity = "0.95";
    };
  };

{
  hwc.blender = {
    enable = true;

    # Single front-of-house root for all user assets/projects/templates/extensions
    mediaRoot       = "${config.home.homeDirectory}/05-media/blender";
    renderOutputDir = "${config.home.homeDirectory}/05-media/blender/renders";
    tempDir         = "${config.home.homeDirectory}/.cache/blender";

    # Extensions: auto-install every *.zip under ${mediaRoot}/extensions
    extensionsRoot = "${config.home.homeDirectory}/05-media/blender/extensions";
    autoInstallAllZipsInExtensionsRoot = true;

    # Enable addons by their final folder names (see note below)
    enableAddons = [
      "hwc_deck_tools"
      "ConstructionLines_0_9_6_9_4"
      "home_builder_4"
      # add more if needed after you see the extracted names
    ];

    # Your deck tools wiring (scripts live under mediaRoot)
    deckTools = {
      enable       = true;
      cutlistXlsx  = "${config.home.homeDirectory}/05-media/blender/data/deck_cutlist.xlsx";
      setupPy      = "${config.home.homeDirectory}/05-media/blender/scripts/deck_kit_setup.py";
      exportCsvPy  = "${config.home.homeDirectory}/05-media/blender/scripts/export_deck_parts_to_csv.py";
    };

    # Optional: add or override asset libraries (defaults point to mediaRoot/assets/*)
    # assetLibraries = {
    #   HDRI      = "${config.home.homeDirectory}/05-media/blender/assets/hdri";
    #   Textures  = "${config.home.homeDirectory}/05-media/blender/assets/textures";
    #   Models    = "${config.home.homeDirectory}/05-media/blender/assets/models";
    #   Materials = "${config.home.homeDirectory}/05-media/blender/assets/materials";
    #   Brushes   = "${config.home.homeDirectory}/05-media/blender/assets/brushes";
    # };

    # Optional: extra Python to run at startup
    # extraStartupPy = ''
    # try:
    #     bpy.context.scene.render.engine = "BLENDER_EEVEE"
    # except Exception:
    #     pass
    # '';

    # Hyprland niceties (float/center Preferences, Alt+F4 closes window)
    addWindowRules = true;
    addAltF4       = true;
    preferenceSize = "1100 800";
  };
}






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
