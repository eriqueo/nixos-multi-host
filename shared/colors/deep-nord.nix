# shared/colors/deep-nord.nix - Global Deep Nord color scheme
# A darker, creamier version of Nord for better eye comfort

{
  colors = {
    # Base colors
    background = "#1f2329";      # Darker than Nord
    foreground = "#f2f0e8";      # Warm cream
    
    # Selection colors
    selection_bg = "#88c0d0";
    selection_fg = "#1f2329";
    
    # Cursor
    cursor = "#f2f0e8";
    cursor_text = "#1f2329";
    
    # URL/links
    url = "#88c0d0";
    
    # Nord color palette adapted for Deep Nord
    # Dark colors (normal)
    color0  = "#3b4252";  # black
    color1  = "#bf616a";  # red
    color2  = "#a3be8c";  # green  
    color3  = "#ebcb8b";  # yellow
    color4  = "#81a1c1";  # blue
    color5  = "#b48ead";  # magenta
    color6  = "#88c0d0";  # cyan
    color7  = "#f2f0e8";  # white (cream)
    
    # Bright colors
    color8  = "#4c566a";  # bright black
    color9  = "#bf616a";  # bright red
    color10 = "#a3be8c";  # bright green
    color11 = "#ebcb8b";  # bright yellow
    color12 = "#81a1c1";  # bright blue
    color13 = "#b48ead";  # bright magenta
    color14 = "#8fbcbb";  # bright cyan
    color15 = "#f2f0e8";  # bright white (cream)
    
    # Nord semantic colors for UI elements
    nord0  = "#1f2329";  # darkest (our custom background)
    nord1  = "#3b4252";  # dark
    nord2  = "#434c5e";  # medium dark
    nord3  = "#4c566a";  # medium
    nord4  = "#d8dee9";  # medium light
    nord5  = "#e5e9f0";  # light
    nord6  = "#f2f0e8";  # lightest (our custom foreground)
    nord7  = "#8fbcbb";  # frost cyan
    nord8  = "#88c0d0";  # frost blue
    nord9  = "#81a1c1";  # frost light blue
    nord10 = "#5e81ac";  # frost dark blue
    nord11 = "#bf616a";  # aurora red
    nord12 = "#d08770";  # aurora orange
    nord13 = "#ebcb8b";  # aurora yellow
    nord14 = "#a3be8c";  # aurora green
    nord15 = "#b48ead";  # aurora purple
    
    # Transparency values
    opacity_terminal = "0.95";
    opacity_inactive = "0.90";
    
    # CSS/Web colors (with # prefix for web use)
    css = {
      background = "#1f2329";
      foreground = "#f2f0e8";
      accent = "#88c0d0";
      warning = "#ebcb8b";
      error = "#bf616a";
      success = "#a3be8c";
      info = "#81a1c1";
    };
  };
}