{ ... }:
{
  systemd.services.arr-config-permissions.wants = [ "network-online.target" ];
  systemd.services.arr-config-permissions.after  = [ "network-online.target" ];
}