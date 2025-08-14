{ lib, config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  profileBase = "${homeDir}/.thunderbird";  # Thunderbird will create the real profile under this
in
{
  config = {
    # Packages
    home.packages = with pkgs; [
      thunderbird
      protonmail-bridge
    ];

    # ProtonMail Bridge user service to keep connection stable
    systemd.user.services.protonmail-bridge = {
      Unit.Description = "ProtonMail Bridge";
      Service.ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
      Install.WantedBy = [ "default.target" ];
    };

    # Declarative config files that Thunderbird/Betterbird expects
    home.file = {
      # Enable userChrome.css
      "${profileBase}/user.js".text = ''
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

        // Layout + view defaults
        user_pref("mail.pane_config.dynamic", 1); // vertical layout
        user_pref("mail.threadpane.use_correspondents", false);
        user_pref("mailnews.default_sort_type", 18); // sort by date
        user_pref("mailnews.default_sort_order", 2); // descending
        user_pref("mailnews.default_view_flags", 1); // threaded

        // Tags: name, shortcut number, color
        user_pref("mailnews.tags", "@Action,1,#FF0000,@Waiting,2,#FFA500,@Read Later,3,#0000FF,@Today,4,#FFFF00,@Clients,5,#00FF00,@Finance,6,#808080");
      '';

      # Gruvbox-style UI tweaks
      "${profileBase}/chrome/userChrome.css".text = ''
        @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

        /* Gruvbox Dark overrides */
        :root {
          --inbox-bg: #282828;
          --inbox-text: #ebdbb2;
          --highlight: #fabd2f;
        }

        #threadTree treechildren::-moz-tree-row(selected, focus) {
          background-color: var(--highlight) !important;
        }
        treechildren::-moz-tree-cell-text {
          color: var(--inbox-text) !important;
        }
      '';

      # Base filter template (to be copied into each account's filter dir or imported)
      "${profileBase}/filters/msgFilterRules.dat".text = ''
        version="9"
        logging="yes"

        name="Tag Clients - Action"
        enabled="yes"
        type="1"
        action="AddTag"
        actionValue="@Action"
        action="AddTag"
        actionValue="@Clients"
        condition="OR (from,contains,bmyincplans.com) (subject,contains,Estimate)"

        name="Move Promos"
        enabled="yes"
        type="1"
        action="Move to folder"
        actionValue="mailbox://<account-identifier>/Promotions"
        condition="OR (subject,contains,unsubscribe) (subject,contains,% off) (subject,contains,sale)"

        name="Finance"
        enabled="yes"
        type="1"
        action="AddTag"
        actionValue="@Finance"
        condition="OR (subject,contains,invoice) (subject,contains,receipt) (from,contains,intuit.com)"
      '';
    };

    # Optional session variable helpful for scripting
    home.sessionVariables.THUNDERBIRD_PROFILE = "default-release";
  };
}

