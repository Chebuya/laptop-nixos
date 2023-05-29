{ stable, inputs, config, pkgs, lib, ...}:

{
  nixpkgs.config.permittedInsecurePackages = [
#    "openssl-1.1.1t"
  ];
  nixpkgs.config.allowUnfree = true;

  age.secrets = {
    sssweden = { file = ./secrets/sssweden.age; owner = "shadowsocks"; group = "shadowsocks"; };
    ssturkey = { file = ./secrets/ssturkey.age; owner = "shadowsocks"; group = "shadowsocks"; };
    ssfinland = { file = ./secrets/ssfinland.age; owner = "shadowsocks"; group = "shadowsocks"; };
    ssmoldova = { file = ./secrets/ssmoldova.age; owner = "shadowsocks"; group = "shadowsocks"; };
    ssdomain = { file = ./secrets/ssdomain.age; owner = "shadowsocks"; group = "shadowsocks"; };
    cloudflared = { file = ./secrets/cloudflared.age; owner = "cloudflared"; group = "cloudflared"; };
    precise = { file = ./secrets/precise.age; owner = "chebuya"; group = "users"; };
    blogrs = { file = ./secrets/blogrs.age; owner = "chebuya"; group = "users"; };
    blogrs_webhook = { file = ./secrets/blogrs_webhook.age; owner = "chebuya"; group = "users"; };
  };

  age.identityPaths = [ "/home/chebuya/.ssh/.agenix/id_ed25519" ];

  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.secrets = {
#    "/crypto_keyfile.bin" = null;
  };

  networking = {
    nameservers = [ "127.0.0.1" "::1" ];
    networkmanager.dns = "none";
    hostName = "laptop";
    networkmanager.enable = true;
    interfaces."wlp1s0".proxyARP = true;
  };

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "en_GB.UTF-8";

  sound.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.wrappers = {
    firejail = {
      source = "${pkgs.firejail.out}/bin/firejail";
    };
  };
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };

  users.users.chebuya = {
    isNormalUser = true;
    description = "Chebuya";
    extraGroups = [ "networkmanager" "wheel" "audio" "libvirtd" "wireshark" ];
  };
  
  system.stateVersion = "22.11";
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    videoDrivers = [ "amdgpu" ];
    displayManager.defaultSession = "xfce";
    config = ''
      section "OutputClass"
      Identifier "AMD"
      MatchDriver "amdgpu"
      Driver "amdgpu"
      Option "TearFree" "true"
      EndSection
    '';
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    libvirtd.enable = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    listenAddresses = [ { addr = "100.77.100.24"; port = 22; } { addr = "127.0.0.1"; port = 22; } ];
  };
  
  services.udev.packages = [ pkgs.yubikey-personalization ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "curses";
  };
 
  services.tailscale.enable = true;
  services.yubikey-agent.enable = true;
  services.flatpak.enable = true;
  programs.wireshark.enable = true;
  programs.firejail.enable = true; 
  programs.command-not-found.enable = false;
  programs.fish.promptInit = ''
    any-nix-shell fish --info-right | source
  '';
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "google-chrome" "exec -a $0 ${google-chrome}/bin/google-chrome-stable $@")
    any-nix-shell
    pinentry
    quartus-prime-lite
    pcsctools
    linuxPackages.usbip
    yubioath-flutter
    yubikey-personalization
    yubikey-personalization-gui
    yubico-piv-tool
    yubikey-touch-detector
    yubikey-manager-qt
    yubikey-manager
    yubico-pam
    firejail
    xfce.xfce4-weather-plugin
    xfce.xfce4-mailwatch-plugin
    xfce.thunar-dropbox-plugin
    xfce.thunar-archive-plugin
    xfce.xfce4-xkb-plugin
    xfce.xfce4-clipman-plugin
    traceroute
    pavucontrol
    pasystray
    google-chrome
    inputs.agenix.packages.x86_64-linux.default 
    inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin
   ];

  environment.etc."yubinotify" = {
    mode = "0555";
    text = ''
      #!/bin/sh

      ${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector -stdout | while read line; do
      if [[ $line == U2F_1* ]]; then
        ${pkgs.libnotify}/bin/notify-send "YubiKey" "Waiting for touch..." --icon=fingerprint -t 8000
      fi
       
      done
    '';
  };

  environment.etc."batterynotify" = {
    mode = "0555";
    text = ''
       #!/bin/sh

    while :
    do
       battery=$(cat /sys/class/power_supply/BAT0/capacity)
       if [ "$battery" -lt 15 ]; then 
        curl -d "Low battery" ntfy.sh/Laptop_hnw19r # please, do not abuse that, i'm too lazy to put it in agenix.
       fi
       sleep 600
    done
    '';
  };

  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ foo2zjs fxlinuxprint ];
  hardware.opengl.driSupport32Bit = true;
  programs.steam.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8081 59100 34844 8888 4780 ];
    allowedUDPPorts = [ 61385 59100 59200 64083 8888 ];
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
    checkReversePath = "loose";
  };  

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      server_names = [ "cloudflare" ];
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  systemd.services.ttyd.script = lib.mkForce ''
    ${pkgs.ttyd}/bin/ttyd \
      --port 7681 \
      --interface lo \
      --client-option enableZmodem=true \
      --client-option enableSixel=true \
      --client-option 'theme={"background": "#171717", "black": "#3F3F3F", "red": "#705050", "green": "#60B48A", "yellow": "#DFAF8F", "blue": "#9AB8D7", "magenta": "#DC8CC3", "cyan": "#8CD0D3", "white": "#DCDCCC", "brightBlack": "#709080", "brightRed": "#DCA3A3", "brightGreen": "#72D5A3", "brightYellow": "#F0DFAF", "brightBlue": "#94BFF3", "brightMagenta": "#EC93D3", "brightCyan": "#93E0E3", "brightWhite": "#FFFFFF"}' \
      ${pkgs.shadow}/bin/login
  '';

  services.ttyd.enable = true;

  systemd.services.syncthing = {
    enable = true;
    description = "syncthing";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5";
      User="chebuya";
    };
    path = with pkgs; [ syncthing ];
    script = ''syncthing'';
  };

  systemd.services.yubinotify = {
    enable = true;
    description = "yubinotify";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5";
      User="chebuya";
      Type="simple";
      ExecStart="/etc/yubinotify";
      Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";
    };
    path = with pkgs; [ gnupg ];
  };

  systemd.services.loginnotify = {
    enable = false;
    description = "loginnotify";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5";
      User="chebuya";
      Type="simple";
    };
    script = ''journalctl -f | grep --line-buffered "session opened" | xargs -I{} curl -d "Login detected" ntfy.sh/Laptop_hnw19r'';
    path = with pkgs; [ curl ];
  };

  systemd.services.batterynotify = {
    enable = true;
    description = "batterynotify";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5";
      User="chebuya";
      Type="simple";
      Exec="/etc/batterynotify";
    };
    path = with pkgs; [ curl ];
  };

  users.users.qbit = {
    group = "users";
    isSystemUser = true;
    createHome = true;
    home = "/var/lib/qbit";
  };

  systemd.services.qbitnox = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "defaultgateway.service" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 10;
      User = "qbit";
      Group = "users";
    };
    script = '' 
      ${pkgs.qbittorrent-nox}/bin/qbittorrent-nox
    '';
  };    

  users.users.shadowsocks = {
    group = "shadowsocks";
    isSystemUser = true;
  };
  users.groups.shadowsocks = {};

  systemd.services.swedenshadowsocks = {
    enable = true;
    description = "Shadowsocks";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Restart = "always"; RestartSec = "5"; User="shadowsocks"; Group="shadowsocks"; };
    script = ''
     password=$(cat "${config.age.secrets.sssweden.path}")
     domain="sweden"$(cat "${config.age.secrets.ssdomain.path}") 
     ss-local -s $domain -p 443 -l 1080 -b 127.0.0.1 -k $password -m "xchacha20-ietf-poly1305" --plugin "v2ray-plugin" --plugin-opts "tls;loglevel=none;host="$domain
    '';
    path = with pkgs; [ shadowsocks-libev shadowsocks-v2ray-plugin ];
  };

  systemd.services.moldovashadowsocks = {
    enable = true;
    description = "Shadowsocks";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Restart = "always"; RestartSec = "5"; User="shadowsocks"; Group="shadowsocks"; };
    script = ''
     password=$(cat "${config.age.secrets.ssmoldova.path}")
     domain="moldova"$(cat "${config.age.secrets.ssdomain.path}") 
     ss-local -s $domain -p 443 -l 1081 -b 127.0.0.1 -k $password -m "xchacha20-ietf-poly1305" --plugin "v2ray-plugin" --plugin-opts "tls;loglevel=none;host="$domain
    '';
    path = with pkgs; [ shadowsocks-libev shadowsocks-v2ray-plugin ];
  };

  systemd.services.finlandshadowsocks = {
    enable = true;
    description = "Shadowsocks";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Restart = "always"; RestartSec = "5"; User="shadowsocks"; Group="shadowsocks"; };
    script = ''
     password=$(cat "${config.age.secrets.ssfinland.path}")
     domain="finland"$(cat "${config.age.secrets.ssdomain.path}") 
     ss-local -s $domain -p 443 -l 1082 -b 127.0.0.1 -k $password -m "xchacha20-ietf-poly1305" --plugin "v2ray-plugin" --plugin-opts "tls;loglevel=none;host="$domain
    '';
    path = with pkgs; [ shadowsocks-libev shadowsocks-v2ray-plugin ];
  };

  systemd.services.turkeyshadowsocks = {
    enable = true;
    description = "Shadowsocks";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Restart = "always"; RestartSec = "5"; User="shadowsocks"; Group="shadowsocks"; };
    script = ''
     password=$(cat "${config.age.secrets.ssturkey.path}")
     domain="turkey"$(cat "${config.age.secrets.ssdomain.path}") 
     ss-local -s $domain -p 443 -l 1083 -b 127.0.0.1 -k $password -m "xchacha20-ietf-poly1305" --plugin "v2ray-plugin" --plugin-opts "tls;loglevel=none;host="$domain
    '';
    path = with pkgs; [ shadowsocks-libev shadowsocks-v2ray-plugin ];
  };

  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
  };
  users.groups.cloudflared = {};

  systemd.services.cloudflared = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 10;
      User = "cloudflared";
      Group = "cloudflared";
    };
    script = ''
     token=$(cat ${config.age.secrets.cloudflared.path})
     cloudflared tunnel --no-autoupdate run --token=$token
    '';
    path = with pkgs; [ cloudflared ]; 
  };

  services.nginx.enable = true;

  services.nginx.virtualHosts."_" = {
    forceSSL = false;
    listen = [{port = 8081;  addr="0.0.0.0"; ssl=false;}];
    root = "/var/www/";
    extraConfig = "index  index.html index.htm;";
    locations."/files/".extraConfig = ''
      alias "/var/www/html/";
      try_files $uri $uri/ =404;
      autoindex on;
      index  ___i;
      autoindex_format json;
      disable_symlinks off;
    '';
    locations."/".extraConfig = ''
       root /var/www/filebrowser;
    '';
  };

  services.nginx.virtualHosts."__" = {
    forceSSL = false;
    listen = [{port = 8082;  addr="127.0.0.1"; ssl=false;}];
    locations."/".extraConfig = ''
      proxy_redirect off;
      proxy_pass http://localhost:7681;
      proxy_set_header Host $host;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
    '';
    locations."/syncthing/".extraConfig = ''
      proxy_set_header        Host localhost;
      proxy_set_header        Referer  http://localhost:8384;
      proxy_set_header        X-Real-IP $remote_addr;
      proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto $scheme;
      proxy_pass              http://localhost:8384/;
      add_header X-Content-Type-Options "nosniff";
    '';
    locations."/qbittorrent/".extraConfig = ''
      proxy_http_version      1.1;
      proxy_set_header        Host localhost:4780;
      proxy_set_header        X-Forwarded-Host   $http_host;
      proxy_set_header        X-Forwarded-For    $remote_addr;
      proxy_pass              http://localhost:4780/;
      proxy_cookie_path       /                  "/; Secure";
      add_header X-Content-Type-Options "nosniff";
    '';
  };
}
