# virtualization.nix
# Virtual machines, Windows compatibility layers, and sandboxed app environments.
# Wine/Bottles + QEMU/KVM for SketchUp VMs
{ pkgs, ... }:

{
  # Wine/Bottles compatibility layer packages (home-manager)
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
    # VM tools (user-accessible)
    virt-manager
    virt-viewer
  ];
}

