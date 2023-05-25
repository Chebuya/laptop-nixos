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
  services.kdeconnect.enable = true;

  home.packages = with pkgs; [
    rustup
    nodePackages.wrangler
    nodejs
    imagemagick
    apostrophe
    nmap
    cloudflared
    htop
    killall
    lsof
    dnsutils
    inetutils
    kitty
    networkmanagerapplet
    any-nix-shell
    fish
    git
    inotify-tools
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    imagemagick
    libsixel
    libnotify
    weechat
    mpv
    util-linux
    prismlauncher
    lutris
    steam-run
    android-studio
    android-tools
    monero-gui
    gnome.zenity
    libreoffice
    lrzsz
    chromium
    inkscape
    obs-studio
    dropbox
    wireguard-tools
    lua5_4
    autossh
    neofetch
    krita
    winetricks
    tor-browser-bundle-bin
    papirus-icon-theme
    shadowsocks-libev
    shadowsocks-v2ray-plugin
    virt-manager
    discord-canary
    tdesktop
    (callPackage ./derivations/audiorelay.nix {})
  ];

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      matklad.rust-analyzer
    ];
  };

  xdg.desktopEntries = {
    keepassxc = {
      name = "KeePassXC";
      icon = "keepassxc";
      exec = ''sh -c "cat /run/agenix/precise | ${pkgs.keepassxc}/bin/keepassxc --pw-stdin /home/chebuya/Dropbox/Sync/passwords.kdbx"'';
      type = "Application";
    };
  };

  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };
}
