# hosts/laptop/modules/graphics.nix
# Creative and graphics applications for laptop
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Creative applications
    gimp              # GNU Image Manipulation Program
    inkscape          # Vector graphics editor
    blender           # 3D creation suite (for occasional use)
  ];

  # GIMP configuration for consistent theming
  home.file.".config/GIMP/2.10/gimprc".text = ''
    # GIMP configuration
    (theme "Dark")
    (icon-theme "Symbolic")
    
    # Interface preferences
    (toolbox-color-area yes)
    (toolbox-foo-area no)
    (toolbox-image-area no)
    (toolbox-wilber no)
    
    # Display settings
    (default-view
      (show-menubar yes)
      (show-rulers yes)
      (show-scrollbars yes)
      (show-statusbar yes)
      (show-selection yes)
      (show-layer-boundary yes)
      (show-guides yes)
      (show-grid no)
      (show-sample-points yes))
  '';

  # Inkscape preferences for dark theme
  home.file.".config/inkscape/preferences.xml".text = ''
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <inkscape>
      <group id="theme">
        <group id="darkTheme" value="1" />
        <group id="symbolicIcons" value="1" />
      </group>
      <group id="dialogs">
        <group id="fillstroke" value="1" />
      </group>
    </inkscape>
  '';
}