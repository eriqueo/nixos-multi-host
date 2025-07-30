# virtualization.nix
# Virtual machines, Windows compatibility layers, and sandboxed app environments.
# Start: Bottles/Wine/SketchUp. Extend for QEMU, podman, etc. as needed.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bottles
    wineWowPackages.staging
    winetricks
    # SketchUp/Wine helper libs
    libGL
    libGLU
    libxkbcommon
    vulkan-loader
    vulkan-tools
    alsa-lib
    fontconfig
    freetype
    cups
    gnutls
    openssl
    dbus
    expat
    libuuid
    # Add more as needed for future VM/compat apps
  ];
}

