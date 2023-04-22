{ inputs, home, config, lib, pkgs, specialArgs, ... }:

let
  schema = pkgs.gsettings-desktop-schemas;
  patchDesktop = pkg: appName: from: to:
    with pkgs; let
      zipped = lib.zipLists from to;
      # Multiple operations to be performed by sed are specified with -e
      sed-args = builtins.map
        ({ fst, snd }: "-e 's#${fst}#${snd}#g'")
        zipped;
      concat-args = builtins.concatStringsSep " " sed-args;
    in
    lib.hiPrio
      (pkgs.runCommand "$patched-desktop-entry-for-${appName}" { } ''
        ${coreutils}/bin/mkdir -p $out/share/applications
        ${gnused}/bin/sed ${concat-args} \
         ${pkg}/share/applications/${appName}.desktop \
         > $out/share/applications/${appName}.desktop
      '');
in {
  nixpkgs.config.allowUnfree = true;
  home.username = "chebuya";
  home.stateVersion = "22.11";
  #services.picom.enable = true;
  #services.picom.vSync = true;
  
  services.kdeconnect.enable = true;

#  nixpkgs.overlays = [
#    (self: super: {
#      waybar = super.waybar.overrideAttrs (oldAttrs: {
#        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
#      });
#    })
#  ];

  home.packages = with pkgs; [
    kitty
    any-nix-shell
    fish
    git
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.unblank
    gnomeExtensions.unite
    gnomeExtensions.dash-to-dock
    gnomeExtensions.appindicator
    gnomeExtensions.gsconnect
    python3
#    grim
#    ayu-theme-gtk
    inotify-tools
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
#    cantarell-fonts
#    font-awesome
#    lxqt.lxqt-qtplugin
#    libsForQt5.qtstyleplugin-kvantum
    pulseaudio
#    kdeconnect
#    wl-clipboard 
#    slurp
    alacritty
#    fuzzel
#    ripcord
#    kitty
    imagemagick
    libsixel
    libnotify
#    mako
#    hyprpaper
    weechat
    graphviz
    mpv
    util-linux
#    waybar
    prismlauncher
    qbittorrent
    lutris
    steam-run
    android-studio
    android-tools
    monero-gui
#    mailspring
    gnome.zenity
    libreoffice
    chromium
    syncthingtray
    inkscape
    obs-studio
    firefox
    openjdk17
    distrobox
    rustup
    dropbox
    wireguard-tools
    lua5_4
    autossh
    neofetch
    krita
    gcolor3
    wineWowPackages.stable
    winetricks
    github-desktop
    tor-browser-bundle-bin
    papirus-icon-theme
    shadowsocks-libev
    shadowsocks-v2ray-plugin
    gnome.geary
    gnome.gnome-boxes
    xdg-utils
    discord
    tdesktop
    keepassxc
      (patchDesktop keepassxc "org.keepassxc.KeePassXC"
      [
        "Exec=keepassxc %f"
      ]
      [
        "Exec=bash -c \"cat /home/chebuya/.pwd | keepassxc --pw-stdin /home/chebuya/Dropbox/Sync/passwords.kdbx\""
      ])
#    (callPackage ./derivations/audiorelay {})
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhsWithPackages (ps: with ps; [ rustup zlib openssl.dev pkg-config ]);
    extensions = with pkgs.vscode-extensions; [
      ms-vscode.cpptools
    ];
  };

  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

 # home.sessionVariables = {
 #   GTK_THEME = "Adwaita:dark";
 #   GTK_USE_PORTAL = "1";
 #  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.gnome.gnome-themes-extra;
    name = "Adwaita";
    size = 24;
    x11.enable = true;
  };

  #fonts.fontconfig.enable = true;

  xresources.properties = {
    "Xcursor.theme" = "Adwaita";
    "Xcursor.size"  = 24;
  };

  #qt = {
  #  enable = true;
  #  platformTheme = "gtk";
  #  style = {
  #    package = pkgs.ayu-theme-gtk;
  #  };
  #};

  home.file = {
    #".gtkrc-2.0".source = ../../config/dracula/gtk-2.0/gtkrc-2.0;
  };

  #gtk = {
  #  enable = true;

  #  gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    
  #  gtk2.extraConfig = ''
  #    gtk-cursor-theme-name="Adwaita"
  #    gtk-cursor-theme-size="24";
  #  '';
  #  gtk3.extraConfig = {
  #    "gtk-cursor-theme-name" = "Adwaita";
  #    "gtk-cursor-theme-size" = 24;
  #  };
  # 
  #  iconTheme = {
  #    name = "Papirus-Dark";
  #    package = pkgs.papirus-icon-theme;
  #  };
  #};
}
