{ config, lib, pkgs, ... }:

let
  cfg = config.hwc.blender;
  blenderVer = lib.versions.majorMinor pkgs.blender.version;

  # Centralized path definitions with validation
  paths = {
    configDir = "${config.xdg.configHome}/blender/${blenderVer}/config";
    userScriptsRoot = "${config.xdg.configHome}/blender/scripts";
    addonsRoot = "${config.xdg.configHome}/blender/scripts/addons";
    startupRoot = "${config.xdg.configHome}/blender/scripts/startup";
    mediaRoot = cfg.mediaRoot;
    extensionsRoot = cfg.extensionsRoot;
    renderOutputDir = cfg.renderOutputDir;
    tempDir = cfg.tempDir;
  };

  # Validate that required paths exist or can be created
  validatePath = path: description:
    lib.warnIf (path == "") "Empty path provided for ${description}";

  # Default asset libraries with better organization
  defaultAssetLibraries = {
    HDRI = "${paths.mediaRoot}/assets/hdri";
    Textures = "${paths.mediaRoot}/assets/textures";
    Models = "${paths.mediaRoot}/assets/models";
    Materials = "${paths.mediaRoot}/assets/materials";
    Brushes = "${paths.mediaRoot}/assets/brushes";
  };

  # Resolved asset libraries
  assetLibs = if cfg.assetLibraries == {} 
    then defaultAssetLibraries 
    else cfg.assetLibraries;

  # Safer startup script generation
  generateStartupScript = let
    libsJson = builtins.toJSON assetLibs;
    enableJson = builtins.toJSON cfg.enableAddons;
  in ''
    import bpy
    import os
    import json
    import logging

    # Set up logging for better error tracking
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    def safe_expand_path(path):
        """Safely expand user paths with validation."""
        if not path:
            return ""
        try:
            expanded = os.path.expanduser(path)
            return expanded if os.path.exists(os.path.dirname(expanded)) else ""
        except Exception as e:
            logger.warning(f"Failed to expand path {path}: {e}")
            return ""

    def setup_asset_libraries():
        """Configure asset libraries with error handling."""
        try:
            asset_libs = json.loads('''${libsJson}''')
            prefs = bpy.context.preferences
            assets = prefs.asset_libraries
            existing = {a.name: a for a in assets}
            
            for name, path in asset_libs.items():
                expanded_path = safe_expand_path(path)
                if not expanded_path:
                    logger.warning(f"Skipping asset library {name}: invalid path {path}")
                    continue
                    
                if name in existing:
                    existing[name].path = expanded_path
                    logger.info(f"Updated asset library {name}: {expanded_path}")
                else:
                    library = assets.new(name)
                    library.path = expanded_path
                    logger.info(f"Created asset library {name}: {expanded_path}")
        except Exception as e:
            logger.error(f"Failed to setup asset libraries: {e}")

    def enable_addons():
        """Enable addons with proper error handling."""
        try:
            enable_addons = json.loads('''${enableJson}''')
            for addon_name in enable_addons:
                try:
                    bpy.ops.preferences.addon_enable(module=addon_name)
                    logger.info(f"Enabled addon: {addon_name}")
                except Exception as e:
                    logger.warning(f"Failed to enable addon {addon_name}: {e}")
        except Exception as e:
            logger.error(f"Failed to process addon list: {e}")

    def configure_render_settings():
        """Configure render output directory."""
        try:
            render_dir = safe_expand_path('''${cfg.renderOutputDir}''')
            if render_dir:
                for scene in bpy.data.scenes:
                    scene.render.filepath = render_dir
                    logger.info(f"Set render output for scene {scene.name}: {render_dir}")
        except Exception as e:
            logger.error(f"Failed to configure render settings: {e}")

    def configure_temp_directory():
        """Configure temporary directory."""
        try:
            temp_dir = safe_expand_path('''${cfg.tempDir}''')
            if temp_dir:
                bpy.context.preferences.filepaths.temporary_directory = temp_dir
                logger.info(f"Set temporary directory: {temp_dir}")
        except Exception as e:
            logger.error(f"Failed to configure temp directory: {e}")

    # Execute configuration functions
    setup_asset_libraries()
    enable_addons()
    configure_render_settings()
    configure_temp_directory()

    # Execute additional user startup code
    ${cfg.extraStartupPy}
  '';

  # Safer deck tools addon with improved security
  deckToolsAddon = ''
    bl_info = {
        "name": "HWC Deck Tools",
        "blender": (4, 0, 0),
        "category": "Object",
        "version": (0, 1, 0),
        "author": "HWC",
        "description": "Tools for deck construction workflows",
        "support": "COMMUNITY"
    }

    import os
    import bpy
    import logging
    import subprocess
    import sys
    from pathlib import Path

    logger = logging.getLogger(__name__)

    def safe_path_expand(path_str):
        """Safely expand and validate paths."""
        if not path_str:
            return None
        try:
            path = Path(path_str).expanduser().resolve()
            return str(path) if path.exists() else None
        except Exception as e:
            logger.warning(f"Invalid path {path_str}: {e}")
            return None

    # Configuration paths with validation
    CUTLIST_PATH = safe_path_expand(r'''${cfg.deckTools.cutlistXlsx or ""}''')
    SETUP_SCRIPT_PATH = safe_path_expand(r'''${cfg.deckTools.setupPy or ""}''')
    EXPORT_SCRIPT_PATH = safe_path_expand(r'''${cfg.deckTools.exportCsvPy or ""}''')

    class HWC_OT_RunSetup(bpy.types.Operator):
        """Run deck setup script safely."""
        bl_idname = "hwc.run_setup"
        bl_label = "HWC Deck Setup"
        bl_description = "Run the deck setup script"

        def execute(self, context):
            if not SETUP_SCRIPT_PATH:
                self.report({'WARNING'}, "Setup script path not configured or file not found")
                return {'CANCELLED'}
            
            try:
                # Use subprocess instead of exec for better security
                result = subprocess.run(
                    [sys.executable, SETUP_SCRIPT_PATH],
                    capture_output=True,
                    text=True,
                    timeout=30  # Prevent hanging
                )
                
                if result.returncode == 0:
                    self.report({'INFO'}, "Setup script completed successfully")
                    logger.info(f"Setup script output: {result.stdout}")
                else:
                    self.report({'ERROR'}, f"Setup script failed: {result.stderr}")
                    logger.error(f"Setup script error: {result.stderr}")
                    
            except subprocess.TimeoutExpired:
                self.report({'ERROR'}, "Setup script timed out")
                return {'CANCELLED'}
            except Exception as e:
                self.report({'ERROR'}, f"Failed to run setup script: {e}")
                logger.error(f"Setup script exception: {e}")
                return {'CANCELLED'}
                
            return {'FINISHED'}

    class HWC_OT_RunExport(bpy.types.Operator):
        """Run deck export script safely."""
        bl_idname = "hwc.run_export"
        bl_label = "HWC Deck Export CSV"
        bl_description = "Export deck parts to CSV"

        def execute(self, context):
            if not EXPORT_SCRIPT_PATH:
                self.report({'WARNING'}, "Export script path not configured or file not found")
                return {'CANCELLED'}
            
            try:
                # Use subprocess instead of exec for better security
                result = subprocess.run(
                    [sys.executable, EXPORT_SCRIPT_PATH],
                    capture_output=True,
                    text=True,
                    timeout=30  # Prevent hanging
                )
                
                if result.returncode == 0:
                    self.report({'INFO'}, "Export completed successfully")
                    logger.info(f"Export output: {result.stdout}")
                else:
                    self.report({'ERROR'}, f"Export failed: {result.stderr}")
                    logger.error(f"Export error: {result.stderr}")
                    
            except subprocess.TimeoutExpired:
                self.report({'ERROR'}, "Export script timed out")
                return {'CANCELLED'}
            except Exception as e:
                self.report({'ERROR'}, f"Failed to run export script: {e}")
                logger.error(f"Export exception: {e}")
                return {'CANCELLED'}
                
            return {'FINISHED'}

    class HWC_PT_DeckToolsPanel(bpy.types.Panel):
        """Main panel for HWC Deck Tools."""
        bl_label = "HWC Deck Tools"
        bl_idname = "HWC_PT_deck_tools"
        bl_space_type = "VIEW_3D"
        bl_region_type = "UI"
        bl_category = "HWC"

        def draw(self, context):
            layout = self.layout
            
            # Setup section
            box = layout.box()
            box.label(text="Setup", icon='SETTINGS')
            row = box.row()
            row.enabled = SETUP_SCRIPT_PATH is not None
            row.operator("hwc.run_setup")
            
            if not SETUP_SCRIPT_PATH:
                box.label(text="Setup script not found", icon='ERROR')
            
            # Export section
            box = layout.box()
            box.label(text="Export", icon='EXPORT')
            row = box.row()
            row.enabled = EXPORT_SCRIPT_PATH is not None
            row.operator("hwc.run_export")
            
            if not EXPORT_SCRIPT_PATH:
                box.label(text="Export script not found", icon='ERROR')
            
            # Info section
            if CUTLIST_PATH:
                box = layout.box()
                box.label(text="Cutlist available", icon='CHECKMARK')

    # Registration
    classes = (
        HWC_OT_RunSetup,
        HWC_OT_RunExport,
        HWC_PT_DeckToolsPanel,
    )

    def register():
        for cls in classes:
            bpy.utils.register_class(cls)
        logger.info("HWC Deck Tools registered")

    def unregister():
        for cls in reversed(classes):
            bpy.utils.unregister_class(cls)
        logger.info("HWC Deck Tools unregistered")

    if __name__ == "__main__":
        register()
  '';

in
{
  options.hwc.blender = {
    enable = lib.mkEnableOption "Blender configuration";
    
    mediaRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/05-media/blender";
      description = lib.mdDoc ''
        Root directory for Blender media files including assets, projects, and renders.
        This directory will be created automatically if it doesn't exist.
      '';
    };

    assetLibraries = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = lib.mdDoc ''
        Custom asset libraries to configure in Blender.
        If empty, default libraries will be created under mediaRoot/assets/.
        
        Example:
        ```nix
        assetLibraries = {
          "My HDRI" = "/path/to/hdri/collection";
          "Custom Models" = "/path/to/models";
        };
        ```
      '';
    };

    extensionsRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/05-media/blender/extensions";
      description = lib.mdDoc ''
        Directory containing Blender extension ZIP files.
        All ZIP files in this directory will be automatically installed as addons.
      '';
    };

    extensionZips = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {};
      description = lib.mdDoc ''
        Specific extension ZIP files to install.
        
        Example:
        ```nix
        extensionZips = {
          "my-addon" = /path/to/my-addon.zip;
        };
        ```
      '';
    };

    autoInstallAllZipsInExtensionsRoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to automatically install all ZIP files found in extensionsRoot.
        Set to false if you want to manually control which extensions are installed.
      '';
    };

    renderOutputDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/05-media/blender/renders";
      description = lib.mdDoc ''
        Default directory for Blender render output.
        This will be set as the default render path for all scenes.
      '';
    };

    tempDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.cache/blender";
      description = lib.mdDoc ''
        Temporary directory for Blender operations.
        Used for caching and temporary files during rendering and operations.
      '';
    };

    startupBlend = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = lib.mdDoc ''
        Path to a custom startup.blend file.
        This file will be loaded when Blender starts.
      '';
    };

    addons = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {};
      description = lib.mdDoc ''
        Additional addons to install by linking directories.
        
        Example:
        ```nix
        addons = {
          "my-custom-addon" = /path/to/addon/directory;
        };
        ```
      '';
    };

    enableAddons = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = lib.mdDoc ''
        List of addon module names to enable automatically on startup.
        
        Example:
        ```nix
        enableAddons = [ "io_import_images_as_planes" "mesh_extra_objects" ];
        ```
      '';
    };

    extraStartupPy = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = lib.mdDoc ''
        Additional Python code to execute during Blender startup.
        This code will be executed after the main configuration is applied.
      '';
    };

    # Window management options
    addWindowRules = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to add Hyprland window rules for better Blender window management.
        This includes floating rules for dialogs and preferences windows.
      '';
    };

    addAltF4 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to add Alt+F4 keybinding for closing windows in Hyprland.
      '';
    };

    preferenceSize = lib.mkOption {
      type = lib.types.str;
      default = "1100 800";
      description = lib.mdDoc ''
        Default size for Blender preferences window in "width height" format.
      '';
    };

    # Deck tools configuration
    deckTools = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc ''
          Whether to enable the HWC Deck Tools addon.
          This provides tools for deck construction workflows.
        '';
      };

      cutlistXlsx = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = "${config.home.homeDirectory}/05-media/blender/data/deck_cutlist.xlsx";
        description = lib.mdDoc ''
          Path to the deck cutlist Excel file.
          Set to null to disable cutlist functionality.
        '';
      };

      setupPy = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = "${config.home.homeDirectory}/05-media/blender/scripts/deck_kit_setup.py";
        description = lib.mdDoc ''
          Path to the deck kit setup Python script.
          This script will be executed when the setup button is clicked.
        '';
      };

      exportCsvPy = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = "${config.home.homeDirectory}/05-media/blender/scripts/export_deck_parts_to_csv.py";
        description = lib.mdDoc ''
          Path to the CSV export Python script.
          This script will be executed when the export button is clicked.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate configuration
    warnings = 
      lib.optional (cfg.mediaRoot == "") "Blender mediaRoot is empty" ++
      lib.optional (cfg.renderOutputDir == "") "Blender renderOutputDir is empty" ++
      lib.optional (cfg.tempDir == "") "Blender tempDir is empty";

    # Install required packages
    home.packages = [ 
      pkgs.blender 
      pkgs.unzip 
      pkgs.findutils 
    ];

    # Set environment variable for Blender scripts
    home.sessionVariables.BLENDER_USER_SCRIPTS = paths.userScriptsRoot;

    # Create directory structure with proper organization
    home.file = let
      createKeepFile = path: {
        "${path}/.keep".text = "";
      };
    in lib.mkMerge [
      # Media directory structure
      (createKeepFile "05-media/blender")
      (createKeepFile "05-media/blender/assets")
      (createKeepFile "05-media/blender/assets/hdri")
      (createKeepFile "05-media/blender/assets/textures")
      (createKeepFile "05-media/blender/assets/models")
      (createKeepFile "05-media/blender/assets/materials")
      (createKeepFile "05-media/blender/assets/brushes")
      (createKeepFile "05-media/blender/projects")
      (createKeepFile "05-media/blender/templates")
      (createKeepFile "05-media/blender/extensions")
      (createKeepFile "05-media/blender/scripts")
      (createKeepFile "05-media/blender/data")
      (createKeepFile "05-media/blender/renders")
      
      # Cache directory
      (createKeepFile ".cache/blender")
    ];

    # XDG configuration files
    xdg.configFile = lib.mkMerge [
      # Basic directory structure
      {
        "blender/.keep".text = "";
        "blender/scripts/.keep".text = "";
        "blender/scripts/startup/.keep".text = "";
        "blender/scripts/addons/.keep".text = "";
        "blender/${blenderVer}/config/.keep".text = "";
      }

      # Optional startup blend file
      (lib.mkIf (cfg.startupBlend != null) {
        "blender/${blenderVer}/config/startup.blend".source = cfg.startupBlend;
      })

      # Main startup script with improved error handling
      {
        "blender/scripts/startup/99_hwc_init.py".text = generateStartupScript;
      }

      # HWC Deck Tools addon with security improvements
      (lib.mkIf cfg.deckTools.enable {
        "blender/scripts/addons/hwc_deck_tools/__init__.py".text = deckToolsAddon;
      })

      # Link additional addons
      (lib.mapAttrs' (name: srcPath: {
        name = "blender/scripts/addons/${name}";
        value = { source = srcPath; };
      }) cfg.addons)
    ];

    # Improved activation script with better error handling
    home.activation.blenderExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      
      echo "Setting up Blender extensions..."
      mkdir -p "${paths.addonsRoot}"

      # Function to safely extract ZIP files
      extract_addon_zip() {
        local zip_file="$1"
        local addon_name="$2"
        local target_dir="${paths.addonsRoot}/$addon_name"
        
        echo "Installing addon: $addon_name from $zip_file"
        
        # Remove existing installation
        if [ -d "$target_dir" ]; then
          rm -rf "$target_dir"
        fi
        
        # Create target directory
        mkdir -p "$target_dir"
        
        # Extract with error handling
        if ${pkgs.unzip}/bin/unzip -qq -o "$zip_file" -d "$target_dir"; then
          echo "Successfully installed addon: $addon_name"
        else
          echo "Warning: Failed to extract $zip_file"
          rm -rf "$target_dir"
        fi
      }

      # Install explicit extension ZIPs
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: zipPath: ''
        if [ -f "${zipPath}" ]; then
          extract_addon_zip "${zipPath}" "${name}"
        else
          echo "Warning: Extension ZIP not found: ${zipPath}"
        fi
      '') cfg.extensionZips)}

      # Auto-install ZIPs from extensions directory
      if [ "${lib.boolToString cfg.autoInstallAllZipsInExtensionsRoot}" = "true" ] && [ -d "${cfg.extensionsRoot}" ]; then
        echo "Auto-installing extensions from ${cfg.extensionsRoot}..."
        
        while IFS= read -r -d "" zip_file; do
          if [ -f "$zip_file" ]; then
            base_name="$(basename "$zip_file")"
            addon_name="''${base_name%.zip}"
            extract_addon_zip "$zip_file" "$addon_name"
          fi
        done < <(${pkgs.findutils}/bin/find "${cfg.extensionsRoot}" -maxdepth 1 -type f -name '*.zip' -print0 2>/dev/null || true)
      fi
      
      echo "Blender extensions setup complete."
    '';

    # Hyprland window rules (only if Hyprland is enabled)
    wayland.windowManager.hyprland.settings = lib.mkIf cfg.addWindowRules {
      windowrulev2 = lib.mkAfter [
        # Preferences and dialog windows
        "float,class:^(blender)$,title:^(Blender Preferences.*|Preferences.*|User Preferences.*)$"
        "center,class:^(blender)$,title:^(Blender Preferences.*|Preferences.*|User Preferences.*)$"
        "size ${cfg.preferenceSize},class:^(blender)$,title:^(Blender Preferences.*|Preferences.*|User Preferences.*)$"
        
        # File dialogs and other popups
        "float,class:^(blender)$,title:^(Render|Save|Open|Confirm|File Browser.*|Blender .* Dialog.*)$"
        "center,class:^(blender)$,title:^(Render|Save|Open|Confirm|File Browser.*|Blender .* Dialog.*)$"
      ];
      
      bind = lib.mkIf cfg.addAltF4 (lib.mkAfter [
        "ALT, F4, killactive"
      ]);
    };
  };
}

