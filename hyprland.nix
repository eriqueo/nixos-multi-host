# Add this to your home.nix in the desktop-only section (around line 700+)

# Wofi app launcher (desktop only)
programs.wofi = lib.mkIf (osConfig.desktop or false) {
  enable = true;
  settings = {
    width = 600;
    height = 400;
    location = "center";
    show = "drun";
    prompt = "Search...";
    filter_rate = 100;
    allow_markup = true;
    no_actions = true;
    halign = "fill";
    orientation = "vertical";
    content_halign = "fill";
    insensitive = true;
    allow_images = true;
    image_size = 32;
    gtk_dark = true;
  };
  
  style = ''
    * {
      font-family: "${fonts.mono}", monospace;
      font-size: ${fonts.size.normal}px;
    }
    
    window {
      margin: 0px;
      border: 2px solid ${theme.accent};
      background-color: ${theme.bg};
      border-radius: 12px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
    }
    
    #input {
      margin: 8px;
      padding: 12px 16px;
      border: 1px solid ${theme.border};
      background-color: ${theme.bg-alt};
      color: ${theme.fg};
      border-radius: 6px;
      font-size: ${fonts.size.large}px;
    }
    
    #input:focus {
      border-color: ${theme.accent};
      box-shadow: 0 0 0 2px ${theme.accent}33;
    }
    
    #inner-box {
      margin: 8px;
      border: none;
      background-color: transparent;
    }
    
    #outer-box {
      margin: 0px;
      border: none;
      background-color: transparent;
    }
    
    #scroll {
      margin: 0px;
      border: none;
    }
    
    #text {
      margin: 5px;
      border: none;
      color: ${theme.fg};
    }
    
    #entry {
      padding: 8px 12px;
      margin: 2px 8px;
      border-radius: 6px;
      background-color: transparent;
      color: ${theme.fg};
      border: 1px solid transparent;
    }
    
    #entry:selected {
      background-color: ${theme.accent};
      color: ${theme.bg};
      border-color: ${theme.accent-bright};
    }
    
    #entry:hover {
      background-color: ${theme.bg-alt};
      border-color: ${theme.border};
    }
    
    #entry:selected:hover {
      background-color: ${theme.accent-bright};
      color: ${theme.bg};
    }
    
    #entry img {
      margin-right: 8px;
    }
    
    /* Scrollbar styling */
    scrollbar {
      background-color: ${theme.bg-alt};
      border-radius: 6px;
      width: 8px;
    }
    
    scrollbar slider {
      background-color: ${theme.accent};
      border-radius: 6px;
      min-height: 20px;
    }
    
    scrollbar slider:hover {
      background-color: ${theme.accent-bright};
    }
  '';
};
