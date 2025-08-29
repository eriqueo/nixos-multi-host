# /etc/nixos/shared/themes/deep-nord-gtk.nix

{ pkgs, ... }:

let
  # Import your color palette
  colors = (import ../colors/deep-nord.nix).colors;

  # The name of our new theme
  themeName = "DeepNord-GTK";

in
pkgs.stdenv.mkDerivation {
  name = themeName;

  # Use the original Gruvbox theme as the source
  src = pkgs.gruvbox-gtk-theme;

  # The build script that performs the patching
  installPhase = ''
    # Create the correct directory structure in the output path
    mkdir -p $out/share/themes

    # Copy the original theme content into our new structure
    cp -r $src/share/themes/Gruvbox-Dark $out/share/themes/${themeName}

    # --- THIS IS THE FIX ---
    # Make the copied files writable so we can patch them.
    chmod -R u+w $out/share/themes/${themeName}

    # Define the target CSS files using the new, correct path
    THEME_DIR="$out/share/themes/${themeName}"
    CSS_FILE_3="$THEME_DIR/gtk-3.0/gtk.css"
    CSS_FILE_4="$THEME_DIR/gtk-4.0/gtk.css"

    echo "--- Patching GTK theme in $THEME_DIR ---"
    echo "Patching GTK 3 file: $CSS_FILE_3"
    echo "Patching GTK 4 file: $CSS_FILE_4"

    # --- The Find-and-Replace Magic ---
    # Use sed to replace the color values in the CSS files.
    sed -i 's/#2b2928/${colors.background}/g' $CSS_FILE_3 $CSS_FILE_4
    sed -i 's/#222222/${colors.nord0}/g' $CSS_FILE_3 $CSS_FILE_4
    sed -i 's/#fbf1c7/${colors.foreground}/g' $CSS_FILE_3 $CSS_FILE_4
    sed -i 's/#fe8019/${colors.css.accent}/g' $CSS_FILE_3 $CSS_FILE_4
    sed -i 's/#574f4a/${colors.nord3}/g' $CSS_FILE_3 $CSS_FILE_4
    sed -i 's/#3f51b5/${colors.nord10}/g' $CSS_FILE_3 $CSS_FILE_4
    sed -i 's/#73c48f/${colors.css.success}/g' $CSS_FILE_3 $CSS_FILE_4
    sed -i 's/#ffce51/${colors.css.warning}/g' $CSS_FILE_3 $CSS_FILE_4
    sed -i 's/#fb4934/${colors.css.error}/g' $CSS_FILE_3 $CSS_FILE_4

    # Update the theme's name internally in the index.theme file
    sed -i "s/Name=Gruvbox-Dark/Name=${themeName}/g" $THEME_DIR/index.theme

    echo "--- Patching complete ---"
  '';



}
