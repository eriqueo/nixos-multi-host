		   # Variables
		   $mod = SUPER
		   
		   # Window/Session Management
		   bind = $mod, Return, exec, kitty
		   bind = $mod, Q, killactive
		   bind = $mod, F, fullscreen
		   bind = $mod, Space, exec, wofi --show drun
		   bind = $mod, B, exec, librewolf
		   bind = $mod, E, exec, electron-mail
		   
		   # Screenshots
		   bind = , Print, exec, hyprshot -m region -o ~/Pictures/Screenshots
		   bind = SHIFT, Print, exec, hyprshot -m region -c
		   
		   # Focus movement (SUPER + arrows)
		   bind = $mod, left, movefocus, l
		   bind = $mod, right, movefocus, r
		   bind = $mod, up, movefocus, u
		   bind = $mod, down, movefocus, d
		   
		   # Window movement within workspace (SUPER + ALT + arrows)
		   bind = $mod ALT, left, movewindow, l
		   bind = $mod ALT, right, movewindow, r
		   bind = $mod ALT, up, movewindow, u
		   bind = $mod ALT, down, movewindow, d
		   
		   # Move windows to workspaces (SUPER + CTRL + numbers)
		   bind = $mod CTRL, 1, movetoworkspace, 1
		   bind = $mod CTRL, 2, movetoworkspace, 2
		   bind = $mod CTRL, 3, movetoworkspace, 3
		   bind = $mod CTRL, 4, movetoworkspace, 4
		   bind = $mod CTRL, 5, movetoworkspace, 5
		   bind = $mod CTRL, 6, movetoworkspace, 6
		   bind = $mod CTRL, 7, movetoworkspace, 7
		   bind = $mod CTRL, 8, movetoworkspace, 8
		   bind = $mod CTRL, W, movetoworkspace, 1
		   bind = $mod CTRL, E, movetoworkspace, 2
		   bind = $mod CTRL, J, movetoworkspace, 3
		   bind = $mod CTRL, O, movetoworkspace, 4
		   bind = $mod CTRL, K, movetoworkspace, 5
		   bind = $mod CTRL, C, movetoworkspace, 6
		   bind = $mod CTRL, M, movetoworkspace, 7
		   bind = $mod CTRL, R, movetoworkspace, 8
		   
		   # Switch to workspaces (SUPER + CTRL + ALT + numbers)
             
		   bind = $mod CTRL ALT, 1, workspace, 1
		   bind = $mod CTRL ALT, 2, workspace, 2
		   bind = $mod CTRL ALT, 3, workspace, 3
		   bind = $mod CTRL ALT, 4, workspace, 4
		   bind = $mod CTRL ALT, 5, workspace, 5
		   bind = $mod CTRL ALT, 6, workspace, 6
		   bind = $mod CTRL ALT, 7, workspace, 7
		   bind = $mod CTRL ALT, 8, workspace, 8
		   bind = $mod CTRL ALT, W, workspace, 1
		   bind = $mod CTRL ALT, E, workspace, 2
		   bind = $mod CTRL ALT, J, workspace, 3
		   bind = $mod CTRL ALT, O, workspace, 4
		   bind = $mod CTRL ALT, K, workspace, 5
		   bind = $mod CTRL ALT, C, workspace, 6
		   bind = $mod CTRL ALT, M, workspace, 7
		   bind = $mod CTRL ALT, R, workspace, 8
		   bind = $mod CTRL ALT, left, workspace, e-1
		   bind = $mod CTRL ALT, right, workspace, e+1
		
