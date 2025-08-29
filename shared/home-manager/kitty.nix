# /etc/nixos/shared/home-manager/kitty.nix
{ colors }: # This module takes your color palette as an input
{
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "CaskaydiaCove Nerd Font";
      font_size = 16;
      enable_audio_bell = false;
      window_padding_width = 4;
      background_opacity = "0.95";

      # --- Refactored to use deep-nord.nix ---
      foreground = colors.foreground;
      background = colors.background;
      selection_foreground = colors.selection_fg;
      selection_background = colors.selection_bg;
      cursor = colors.cursor;
      cursor_text_color = colors.cursor_text;
      url_color = colors.url;

      # Normal colors
      color0 = colors.color0;
      color1 = colors.color1;
      color2 = colors.color2;
      color3 = colors.color3;
      color4 = colors.color4;
      color5 = colors.color5;
      color6 = colors.color6;
      color7 = colors.color7;

      # Bright colors
      color8 = colors.color8;
      color9 = colors.color9;
      color10 = colors.color10;
      color11 = colors.color11;
      color12 = colors.color12;
      color13 = colors.color13;
      color14 = colors.color14;
      color15 = colors.color15;
    };
  };
}
