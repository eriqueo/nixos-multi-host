{ config, lib, pkgs, ... }:

let
  cfg = config.hwc.blender;
  blenderVer = lib.versions.majorMinor pkgs.blender.version;
  cfgDir = "${config.xdg.configHome}/blender/${blenderVer}/config";
  userScriptsRoot = "${config.xdg.configHome}/blender/scripts";
  addonsRoot = "${userScriptsRoot}/addons";
  startupRoot = "${userScriptsRoot}/startup";
  media = cfg.mediaRoot;
in
{
  options.hwc.blender = {
    enable = lib.mkEnableOption "Blender configuration";

    mediaRoot = lib.mkOption { type = lib.types.str; default = "${config.home.homeDirectory}/05-media/blender"; };

    assetLibraries = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        HDRI      = "${media}/assets/hdri";
        Textures  = "${media}/assets/textures";
        Models    = "${media}/assets/models";
        Materials = "${media}/assets/materials";
        Brushes   = "${media}/assets/brushes";
      };
    };

    extensionsRoot = lib.mkOption { type = lib.types.str; default = "${media}/extensions"; };
    extensionZips  = lib.mkOption { type = lib.types.attrsOf lib.types.path; default = { }; };
    autoInstallAllZipsInExtensionsRoot = lib.mkOption { type = lib.types.bool; default = true; };

    renderOutputDir = lib.mkOption { type = lib.types.str; default = "${media}/renders"; };
    tempDir         = lib.mkOption { type = lib.types.str; default = "${config.home.homeDirectory}/.cache/blender"; };

    startupBlend = lib.mkOption { type = lib.types.nullOr lib.types.path; default = null; };

    addons = lib.mkOption { type = lib.types.attrsOf lib.types.path; default = { }; };
    enableAddons = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };

    extraStartupPy = lib.mkOption { type = lib.types.lines; default = ""; };

    addWindowRules = lib.mkOption { type = lib.types.bool; default = true; };
    addAltF4       = lib.mkOption { type = lib.types.bool; default = true; };
    preferenceSize = lib.mkOption { type = lib.types.str; default = "1100 800"; };

    deckTools.enable     = lib.mkOption { type = lib.types.bool; default = true; };
    deckTools.cutlistXlsx= lib.mkOption { type = lib.types.nullOr lib.types.path; default = "${media}/data/deck_cutlist.xlsx"; };
    deckTools.setupPy    = lib.mkOption { type = lib.types.nullOr lib.types.path; default = "${media}/scripts/deck_kit_setup.py"; };
    deckTools.exportCsvPy= lib.mkOption { type = lib.types.nullOr lib.types.path; default = "${media}/scripts/export_deck_parts_to_csv.py"; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.blender pkgs.unzip pkgs.findutils ];

    home.sessionVariables.BLENDER_USER_SCRIPTS = userScriptsRoot;

    xdg.configFile."blender/.keep".text = "";
    xdg.configFile."blender/scripts/.keep".text = "";
    xdg.configFile."blender/scripts/startup/.keep".text = "";
    xdg.configFile."blender/scripts/addons/.keep".text = "";
    xdg.configFile."blender/${blenderVer}/config/.keep".text = "";

    xdg.configFile."blender/${blenderVer}/config/startup.blend".source =
      lib.mkIf (cfg.startupBlend != null) cfg.startupBlend;

    home.file."05-media/blender/.keep".text = "";
    home.file."05-media/blender/assets/.keep".text = "";
    home.file."05-media/blender/assets/hdri/.keep".text = "";
    home.file."05-media/blender/assets/textures/.keep".text = "";
    home.file."05-media/blender/assets/models/.keep".text = "";
    home.file."05-media/blender/assets/materials/.keep".text = "";
    home.file."05-media/blender/assets/brushes/.keep".text = "";
    home.file."05-media/blender/projects/.keep".text = "";
    home.file."05-media/blender/templates/.keep".text = "";
    home.file."05-media/blender/extensions/.keep".text = "";
    home.file."05-media/blender/scripts/.keep".text = "";
    home.file."05-media/blender/data/.keep".text = "";
    home.file."05-media/blender/renders/.keep".text = "";
    home.file.".cache/blender/.keep".text = "";

    xdg.configFile = lib.mkMerge (lib.mapAttrsToList (name: srcPath: {
      "blender/scripts/addons/${name}".source = srcPath;
    }) cfg.addons);

    home.activation.blenderExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      mkdir -p "${addonsRoot}"

      ${lib.concatStringsSep "\n" (map (name: ''
        rm -rf "${addonsRoot}/${name}"
        mkdir -p "${addonsRoot}/${name}"
        ${pkgs.unzip}/bin/unzip -qq -o "${cfg.extensionZips.${name}}" -d "${addonsRoot}/${name}"
      '') (builtins.attrNames cfg.extensionZips))}

      if ${lib.boolToString cfg.autoInstallAllZipsInExtensionsRoot}; then
        if [ -d "${cfg.extensionsRoot}" ]; then
          while IFS= read -r -d "" z; do
            base="$(basename "$z")"
            name="''${base%.zip}"
            rm -rf "${addonsRoot}/$name"
            mkdir -p "${addonsRoot}/$name"
            ${pkgs.unzip}/bin/unzip -qq -o "$z" -d "${addonsRoot}/$name"
          done < <(${pkgs.findutils}/bin/find "${cfg.extensionsRoot}" -maxdepth 1 -type f -name '*.zip' -print0)
        fi
      fi
    '';

    xdg.configFile."blender/scripts/startup/99_hwc_init.py".text = let
      libs = builtins.toJSON (lib.mapAttrs (_: v: v) cfg.assetLibraries);
      enable = builtins.toJSON cfg.enableAddons;
    in ''
import bpy, os, json
asset_libs = json.loads('''${libs}''')
enable_addons = json.loads('''${enable}''')
for mod in enable_addons:
    try:
        bpy.ops.preferences.addon_enable(module=mod)
    except Exception:
        pass
prefs = bpy.context.preferences
assets = prefs.asset_libraries
existing = {a.name: a for a in assets}
for name, path in asset_libs.items():
    p = os.path.expanduser(path)
    if not p:
        continue
    if name in existing:
        existing[name].path = p
    else:
        a = assets.new(name)
        a.path = p
for s in bpy.data.scenes:
    try:
        s.render.filepath = os.path.expanduser('''${cfg.renderOutputDir}''')
    except Exception:
        pass
try:
    prefs.filepaths.temporary_directory = os.path.expanduser('''${cfg.tempDir}''')
except Exception:
    pass
${cfg.extraStartupPy}
'';

    xdg.configFile."blender/scripts/addons/hwc_deck_tools/__init__.py".text =
      lib.mkIf cfg.deckTools.enable ''
bl_info = {"name":"HWC Deck Tools","blender":(4,0,0),"category":"Object","version":(0,1,0),"author":"HWC"}
import os, bpy
def _p(p): return os.path.expanduser(p) if p else None
CUTLIST = _p(r'''${cfg.deckTools.cutlistXlsx or ""}''')
SETUP   = _p(r'''${cfg.deckTools.setupPy or ""}''')
EXPORT  = _p(r'''${cfg.deckTools.exportCsvPy or ""}''')
class HWC_OT_run_setup(bpy.types.Operator):
    bl_idname="hwc.run_setup"; bl_label="HWC Deck Setup"
    def execute(self, ctx):
        if SETUP and os.path.exists(SETUP):
            exec(compile(open(SETUP,"rb").read(), SETUP, "exec"), {"__name__":"__main__"})
        return {'FINISHED'}
class HWC_OT_run_export(bpy.types.Operator):
    bl_idname="hwc.run_export"; bl_label="HWC Deck Export CSV"
    def execute(self, ctx):
        if EXPORT and os.path.exists(EXPORT):
            exec(compile(open(EXPORT,"rb").read(), EXPORT, "exec"), {"__name__":"__main__"})
        return {'FINISHED'}
class HWC_PT_panel(bpy.types.Panel):
    bl_label="HWC Deck Tools"; bl_idname="HWC_PT_panel"
    bl_space_type="VIEW_3D"; bl_region_type="UI"; bl_category="HWC"
    def draw(self, ctx):
        l=self.layout; l.operator("hwc.run_setup"); l.operator("hwc.run_export")
def register():
    for c in (HWC_OT_run_setup,HWC_OT_run_export,HWC_PT_panel): bpy.utils.register_class(c)
def unregister():
    for c in (HWC_PT_panel,HWC_OT_run_export,HWC_OT_run_setup): bpy.utils.unregister_class(c)
'';

    wayland.windowManager.hyprland.settings.windowrulev2 =
      lib.mkIf cfg.addWindowRules [
        "float,class:^(blender)$,title:^(Blender Preferences.*|Preferences.*|User Preferences.*)$"
        "center,class:^(blender)$,title:^(Blender Preferences.*|Preferences.*|User Preferences.*)$"
        "size ${cfg.preferenceSize},class:^(blender)$,title:^(Blender Preferences.*|Preferences.*|User Preferences.*)$"
        "float,class:^(blender)$,title:^(Render|Save|Open|Confirm|File Browser.*|Blender .* Dialog.*)$"
        "center,class:^(blender)$,title:^(Render|Save|Open|Confirm|File Browser.*|Blender .* Dialog.*)$"
      ];

    wayland.windowManager.hyprland.settings.bind =
      lib.mkIf cfg.addAltF4 [
        "ALT, F4, killactive"
      ];
  };
}

