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

  # Default asset libraries with better organization
  defaultAssetLibraries = {
    HDRI = "${paths.mediaRoot}/assets/hdri";
    Textures = "${paths.mediaRoot}/assets/textures";
    Models = "${paths.mediaRoot}/assets/models";
    Materials = "${paths.mediaRoot}/assets/materials";
    Brushes = "${paths.mediaRoot}/assets/brushes";
    NodeGroups = "${paths.mediaRoot}/assets/node_groups";
    Worlds = "${paths.mediaRoot}/assets/worlds";
  };

  # Resolved asset libraries
  assetLibs = if cfg.assetLibraries == {} 
    then defaultAssetLibraries 
    else cfg.assetLibraries;

  # Dynamic startup script generation with automatic addon discovery
  generateStartupScript = let
    libsJson = builtins.toJSON assetLibs;
    manualAddonsJson = builtins.toJSON cfg.enableAddons;
    excludeAddonsJson = builtins.toJSON cfg.excludeAddons;
  in ''
    import bpy
    import os
    import json
    import logging
    from pathlib import Path

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

    def discover_addons():
        """Dynamically discover all available addons."""
        addons_root = Path("${paths.addonsRoot}")
        discovered_addons = []
        
        if not addons_root.exists():
            logger.warning(f"Addons directory not found: {addons_root}")
            return discovered_addons
        
        try:
            for addon_path in addons_root.iterdir():
                if addon_path.is_dir() and not addon_path.name.startswith('.'):
                    # Check for __init__.py to confirm it's a Python addon
                    init_file = addon_path / "__init__.py"
                    if init_file.exists():
                        discovered_addons.append(addon_path.name)
                        logger.info(f"Discovered addon: {addon_path.name}")
                    else:
                        # Check for nested addon structure (common with ZIP extractions)
                        for nested_path in addon_path.iterdir():
                            if nested_path.is_dir() and (nested_path / "__init__.py").exists():
                                addon_name = f"{addon_path.name}.{nested_path.name}"
                                discovered_addons.append(addon_name)
                                logger.info(f"Discovered nested addon: {addon_name}")
        except Exception as e:
            logger.error(f"Error discovering addons: {e}")
        
        return discovered_addons

    def enable_addons():
        """Enable addons with dynamic discovery and manual overrides."""
        try:
            # Get manually specified addons
            manual_addons = json.loads('''${manualAddonsJson}''')
            exclude_addons = set(json.loads('''${excludeAddonsJson}'''))
            
            # Discover addons automatically if enabled
            discovered_addons = []
            if ${lib.boolToString cfg.autoDiscoverAddons}:
                discovered_addons = discover_addons()
            
            # Combine manual and discovered addons, removing duplicates and exclusions
            all_addons = list(set(manual_addons + discovered_addons) - exclude_addons)
            
            logger.info(f"Attempting to enable {len(all_addons)} addons")
            
            enabled_count = 0
            failed_count = 0
            
            for addon_name in all_addons:
                try:
                    # Check if addon is already enabled
                    if addon_name in bpy.context.preferences.addons.keys():
                        logger.info(f"Addon already enabled: {addon_name}")
                        enabled_count += 1
                        continue
                    
                    # Try to enable the addon
                    bpy.ops.preferences.addon_enable(module=addon_name)
                    logger.info(f"Enabled addon: {addon_name}")
                    enabled_count += 1
                    
                except Exception as e:
                    logger.warning(f"Failed to enable addon {addon_name}: {e}")
                    failed_count += 1
            
            logger.info(f"Addon enablement complete: {enabled_count} enabled, {failed_count} failed")
            
        except Exception as e:
            logger.error(f"Failed to process addon enablement: {e}")

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
                
                # Create directory if it doesn't exist
                os.makedirs(expanded_path, exist_ok=True)
                    
                if name in existing:
                    existing[name].path = expanded_path
                    logger.info(f"Updated asset library {name}: {expanded_path}")
                else:
                    library = assets.new(name)
                    library.path = expanded_path
                    logger.info(f"Created asset library {name}: {expanded_path}")
        except Exception as e:
            logger.error(f"Failed to setup asset libraries: {e}")

    def configure_render_settings():
        """Configure render output directory with auto-creation."""
        try:
            render_dir = safe_expand_path('''${cfg.renderOutputDir}''')
            if render_dir:
                # Create render directory if it doesn't exist
                os.makedirs(render_dir, exist_ok=True)
                
                for scene in bpy.data.scenes:
                    scene.render.filepath = render_dir + "/"
                    logger.info(f"Set render output for scene {scene.name}: {render_dir}")
        except Exception as e:
            logger.error(f"Failed to configure render settings: {e}")

    def configure_temp_directory():
        """Configure temporary directory with auto-creation."""
        try:
            temp_dir = safe_expand_path('''${cfg.tempDir}''')
            if temp_dir:
                # Create temp directory if it doesn't exist
                os.makedirs(temp_dir, exist_ok=True)
                
                bpy.context.preferences.filepaths.temporary_directory = temp_dir
                logger.info(f"Set temporary directory: {temp_dir}")
        except Exception as e:
            logger.error(f"Failed to configure temp directory: {e}")

    def apply_performance_settings():
        """Apply performance optimizations if enabled."""
        if ${lib.boolToString cfg.optimizePerformance}:
            try:
                prefs = bpy.context.preferences
                
                # Memory & Limits
                prefs.system.memory_cache_limit = ${toString cfg.memoryCacheLimit}
                
                # Viewport settings
                prefs.system.gl_texture_limit = "CLAMP_8192"
                prefs.system.anisotropic_filter = "FILTER_16"
                
                # Cycles settings
                if hasattr(prefs, 'addons') and 'cycles' in prefs.addons:
                    cycles_prefs = prefs.addons['cycles'].preferences
                    if hasattr(cycles_prefs, 'compute_device_type'):
                        cycles_prefs.compute_device_type = '${cfg.computeDeviceType}'
                        # Refresh devices
                        cycles_prefs.get_devices()
                        for device in cycles_prefs.devices:
                            device.use = True
                
                logger.info("Applied performance optimizations")
            except Exception as e:
                logger.error(f"Failed to apply performance settings: {e}")

    def setup_custom_preferences():
        """Apply custom user preferences."""
        try:
            prefs = bpy.context.preferences
            
            # Interface settings
            prefs.view.show_splash = ${lib.boolToString (!cfg.showSplashScreen)}
            prefs.view.show_tooltips_python = True
            
            # Edit settings
            prefs.edit.use_duplicate_linked = True
            prefs.edit.use_enter_edit_mode = ${lib.boolToString cfg.enterEditModeOnAdd}
            
            # File settings
            prefs.filepaths.use_auto_save_temporary_files = ${lib.boolToString cfg.autoSave}
            if ${lib.boolToString cfg.autoSave}:
                prefs.filepaths.auto_save_time = ${toString cfg.autoSaveTime}
            
            logger.info("Applied custom preferences")
        except Exception as e:
            logger.error(f"Failed to apply custom preferences: {e}")

    # Execute all configuration functions
    logger.info("Starting Blender HWC configuration...")
    setup_asset_libraries()
    enable_addons()
    configure_render_settings()
    configure_temp_directory()
    apply_performance_settings()
    setup_custom_preferences()
    logger.info("Blender HWC configuration complete")

    # Execute additional user startup code
    ${cfg.extraStartupPy}
  '';

  # Enhanced deck tools addon with dynamic script discovery
  deckToolsAddon = ''
    bl_info = {
        "name": "HWC Deck Tools",
        "blender": (4, 0, 0),
        "category": "Object",
        "version": (0, 2, 0),
        "author": "HWC",
        "description": "Dynamic tools for deck construction workflows",
        "support": "COMMUNITY"
    }

    import os
    import bpy
    import logging
    import subprocess
    import sys
    from pathlib import Path

    logger = logging.getLogger(__name__)

    def discover_scripts():
        """Dynamically discover available scripts."""
        scripts_dir = Path("${paths.mediaRoot}/scripts")
        discovered_scripts = {}
        
        if scripts_dir.exists():
            for script_file in scripts_dir.glob("*.py"):
                script_name = script_file.stem
                discovered_scripts[script_name] = str(script_file)
        
        return discovered_scripts

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

    # Configuration paths with validation and dynamic discovery
    CUTLIST_PATH = safe_path_expand(r'''${cfg.deckTools.cutlistXlsx or ""}''')
    DISCOVERED_SCRIPTS = discover_scripts()
    
    # Fallback to configured paths if not found dynamically
    SETUP_SCRIPT_PATH = (DISCOVERED_SCRIPTS.get("deck_kit_setup") or 
                        safe_path_expand(r'''${cfg.deckTools.setupPy or ""}'''))
    EXPORT_SCRIPT_PATH = (DISCOVERED_SCRIPTS.get("export_deck_parts_to_csv") or 
                         safe_path_expand(r'''${cfg.deckTools.exportCsvPy or ""}'''))

    class HWC_OT_RunScript(bpy.types.Operator):
        """Generic script runner for dynamic script execution."""
        bl_idname = "hwc.run_script"
        bl_label = "Run Script"
        bl_description = "Run a Python script safely"
        
        script_path: bpy.props.StringProperty()
        script_name: bpy.props.StringProperty()

        def execute(self, context):
            if not self.script_path or not os.path.exists(self.script_path):
                self.report({'WARNING'}, f"Script not found: {self.script_name}")
                return {'CANCELLED'}
            
            try:
                result = subprocess.run(
                    [sys.executable, self.script_path],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result.returncode == 0:
                    self.report({'INFO'}, f"{self.script_name} completed successfully")
                    if result.stdout:
                        logger.info(f"{self.script_name} output: {result.stdout}")
                else:
                    self.report({'ERROR'}, f"{self.script_name} failed: {result.stderr}")
                    logger.error(f"{self.script_name} error: {result.stderr}")
                    
            except subprocess.TimeoutExpired:
                self.report({'ERROR'}, f"{self.script_name} timed out")
                return {'CANCELLED'}
            except Exception as e:
                self.report({'ERROR'}, f"Failed to run {self.script_name}: {e}")
                return {'CANCELLED'}
                
            return {'FINISHED'}

    class HWC_PT_DeckToolsPanel(bpy.types.Panel):
        """Dynamic panel for HWC Deck Tools."""
        bl_label = "HWC Deck Tools"
        bl_idname = "HWC_PT_deck_tools"
        bl_space_type = "VIEW_3D"
        bl_region_type = "UI"
        bl_category = "HWC"

        def draw(self, context):
            layout = self.layout
            
            # Quick setup section
            if SETUP_SCRIPT_PATH:
                box = layout.box()
                box.label(text="Quick Setup", icon='SETTINGS')
                op = box.operator("hwc.run_script", text="Run Deck Setup")
                op.script_path = SETUP_SCRIPT_PATH
                op.script_name = "Deck Setup"
            
            # Export section
            if EXPORT_SCRIPT_PATH:
                box = layout.box()
                box.label(text="Export", icon='EXPORT')
                op = box.operator("hwc.run_script", text="Export to CSV")
                op.script_path = EXPORT_SCRIPT_PATH
                op.script_name = "CSV Export"
            
            # Dynamic scripts section
            if DISCOVERED_SCRIPTS:
                box = layout.box()
                box.label(text="Available Scripts", icon='SCRIPT')
                
                for script_name, script_path in DISCOVERED_SCRIPTS.items():
                    if script_name not in ["deck_kit_setup", "export_deck_parts_to_csv"]:
                        op = box.operator("hwc.run_script", text=script_name.replace("_", " ").title())
                        op.script_path = script_path
                        op.script_name = script_name
            
            # Info section
            if CUTLIST_PATH:
                box = layout.box()
                box.label(text="Cutlist Available", icon='CHECKMARK')
                box.label(text=f"Path: {os.path.basename(CUTLIST_PATH)}")

    # Registration
    classes = (
        HWC_OT_RunScript,
        HWC_PT_DeckToolsPanel,
    )

    def register():
        for cls in classes:
            bpy.utils.register_class(cls)
        logger.info("HWC Deck Tools registered with dynamic script discovery")

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
        Directories will be created automatically if they don't exist.
        
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

    # Dynamic addon discovery options
    autoDiscoverAddons = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to automatically discover and enable all addons in the addons directory.
        When enabled, all valid Python addons will be enabled automatically.
        This eliminates the need to manually specify addon names.
      '';
    };

    enableAddons = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = lib.mdDoc ''
        List of addon module names to enable manually (in addition to auto-discovered ones).
        This is useful for built-in Blender addons or addons with specific module names.
        
        Example:
        ```nix
        enableAddons = [ "io_import_images_as_planes" "mesh_extra_objects" ];
        ```
      '';
    };

    excludeAddons = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = lib.mdDoc ''
        List of addon module names to exclude from automatic enablement.
        Useful when you want auto-discovery but need to skip problematic addons.
        
        Example:
        ```nix
        excludeAddons = [ "problematic_addon" "another_broken_addon" ];
        ```
      '';
    };

    renderOutputDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/05-media/blender/renders";
      description = lib.mdDoc ''
        Default directory for Blender render output.
        This will be set as the default render path for all scenes and created automatically.
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
        These will be automatically discovered and enabled if autoDiscoverAddons is true.
        
        Example:
        ```nix
        addons = {
          "my-custom-addon" = /path/to/addon/directory;
        };
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

    # Performance and optimization options
    optimizePerformance = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to apply performance optimizations automatically.
        This includes memory cache settings, viewport optimizations, and GPU compute setup.
      '';
    };

    memoryCacheLimit = lib.mkOption {
      type = lib.types.int;
      default = 2048;
      description = lib.mdDoc ''
        Memory cache limit in MB for Blender operations.
        Higher values can improve performance but use more RAM.
      '';
    };

    computeDeviceType = lib.mkOption {
      type = lib.types.enum [ "CUDA" "OPENCL" "OPTIX" "HIP" "ONEAPI" ];
      default = "CUDA";
      description = lib.mdDoc ''
        Compute device type for Cycles rendering.
        Choose based on your GPU: CUDA/OPTIX for NVIDIA, OPENCL/HIP for AMD, ONEAPI for Intel.
      '';
    };

    # User interface preferences
    showSplashScreen = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = lib.mdDoc ''
        Whether to show the Blender splash screen on startup.
      '';
    };

    enterEditModeOnAdd = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to automatically enter edit mode when adding new objects.
      '';
    };

    autoSave = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to enable automatic saving of temporary files.
      '';
    };

    autoSaveTime = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = lib.mdDoc ''
        Auto-save interval in minutes when autoSave is enabled.
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

    # Enhanced deck tools configuration
    deckTools = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc ''
          Whether to enable the HWC Deck Tools addon with dynamic script discovery.
          This provides tools for deck construction workflows and automatically discovers scripts.
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
          If not found, the addon will look for "deck_kit_setup.py" in the scripts directory.
        '';
      };

      exportCsvPy = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = "${config.home.homeDirectory}/05-media/blender/scripts/export_deck_parts_to_csv.py";
        description = lib.mdDoc ''
          Path to the CSV export Python script.
          If not found, the addon will look for "export_deck_parts_to_csv.py" in the scripts directory.
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
      # Media directory structure (expanded for more asset types)
      (createKeepFile "05-media/blender")
      (createKeepFile "05-media/blender/assets")
      (createKeepFile "05-media/blender/assets/hdri")
      (createKeepFile "05-media/blender/assets/textures")
      (createKeepFile "05-media/blender/assets/models")
      (createKeepFile "05-media/blender/assets/materials")
      (createKeepFile "05-media/blender/assets/brushes")
      (createKeepFile "05-media/blender/assets/node_groups")
      (createKeepFile "05-media/blender/assets/worlds")
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

      # Enhanced startup script with dynamic features
      {
        "blender/scripts/startup/99_hwc_init.py".text = generateStartupScript;
      }

      # Enhanced HWC Deck Tools addon with dynamic script discovery
      (lib.mkIf cfg.deckTools.enable {
        "blender/scripts/addons/hwc_deck_tools/__init__.py".text = deckToolsAddon;
      })

      # Link additional addons (these will be auto-discovered if enabled)
      (lib.mapAttrs' (name: srcPath: {
        name = "blender/scripts/addons/${name}";
        value = { source = srcPath; };
      }) cfg.addons)
    ];

    # Enhanced activation script with better error handling and dynamic features
    home.activation.blenderExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      
      echo "Setting up Blender extensions and directories..."
      
      # Create all necessary directories
      mkdir -p "${paths.addonsRoot}"
      mkdir -p "${cfg.mediaRoot}/assets"/{hdri,textures,models,materials,brushes,node_groups,worlds}
      mkdir -p "${cfg.mediaRoot}"/{projects,templates,extensions,scripts,data,renders}
      mkdir -p "${cfg.renderOutputDir}"
      mkdir -p "${cfg.tempDir}"

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
          
          # Check if extraction created a nested directory structure
          local nested_dirs=$(find "$target_dir" -mindepth 1 -maxdepth 1 -type d | wc -l)
          local py_files=$(find "$target_dir" -maxdepth 1 -name "*.py" | wc -l)
          
          # If there's only one directory and no Python files at root, flatten structure
          if [ "$nested_dirs" -eq 1 ] && [ "$py_files" -eq 0 ]; then
            local nested_dir=$(find "$target_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)
            if [ -f "$nested_dir/__init__.py" ]; then
              echo "Flattening nested addon structure for $addon_name"
              mv "$nested_dir"/* "$target_dir/" 2>/dev/null || true
              rmdir "$nested_dir" 2>/dev/null || true
            fi
          fi
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
      
      echo "Blender setup complete. Dynamic addon discovery will handle enablement on startup."
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

