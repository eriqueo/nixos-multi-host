{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    dmidecode
    bolt
  ];
}
