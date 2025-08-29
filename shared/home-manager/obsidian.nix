# /etc/nixos/shared/home-manager/obsidian.nix
{ lib, colors }:
{
  home.file =
    let
      obsidianVaults = [
        "Documents/01-vaults/00_tech"
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
