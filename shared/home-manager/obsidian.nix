# /etc/nixos/shared/home-manager/obsidian.nix
{ lib, colors }:
{
  home.file =
    let
      obsidianVaults = [
        "/home/eric/99-vaults/00_tech"
        "/home/eric/99-vaults/01_hwc"
        "/home/eric/99-vaults/02_personal"
        "/home/eric/99-vaults/03_nixos"
        "/home/eric/99-vaults/04-transcripts"
        "/home/eric/99-vaults/05-website"
        # Add more vaults here
      ];
      obsidianCss = ''
        /* Sourced from deep-nord.nix */
        .theme-dark {
          --background-primary: ${colors.background};
          --background-secondary: ${colors.color0};
          --text-normal: ${colors.foreground};
          --text-accent: ${colors.css.accent};
          --interactive-accent: ${colors.css.accent};
        }
      '';
    in
      lib.mapAttrs'
        (path: _: lib.nameValuePair "${path}/.obsidian/snippets/gruvbox-material.css" { text = obsidianCss; })
        (lib.listToAttrs (lib.map (path: { name = path; value = null; }) obsidianVaults));
}
