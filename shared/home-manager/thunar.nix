# /etc/nixos/shared/home-manager/thunar.nix
{ pkgs }:
{
  # Install Thunar's configuration tool, just in case you need it manually
  home.packages = [ pkgs.xfce.xfconf ];

  # Configure Thunar using the XML file. This is the source of truth.
  home.file.".config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="thunar" version="1.0">
      <property name="default-view" type="string" value="ThunarDetailsView"/>
      <property name="last-view" type="string" value="ThunarDetailsView"/>
      #<property name="misc-show-hidden" type="bool" value="true"/>
      #<property name="last-show-hidden" type="bool" value="true"/>
      <property name="misc-single-click" type="bool" value="false"/>
    </channel>
  '';
}
