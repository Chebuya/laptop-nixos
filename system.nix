{ inputs, config, pkgs, lib, ...}:
{
  age.secrets.sssweden = {
    file = ./secrets/sssweden.age;
    owner = "shadowsocks";
    group = "shadowsocks";
  };

  age.secrets.cloudflarednginx = {
    file = ./secrets/cloudflarednginx.age;
    owner = "cloudflared";
    group = "cloudflared";
  };

  age.secrets.cloudflaredsyncthing = {
    file = ./secrets/cloudflaredsyncthing.age;
    owner = "cloudflared";
    group = "cloudflared";
  };

  age.secrets.cloudflaredssh = {
    file = ./secrets/cloudflaredssh.age;
    owner = "cloudflared";
    group = "cloudflared";
  };

  age.secrets.cloudflaredqbit = {
    file = ./secrets/cloudflaredqbit.age;
    owner = "cloudflared";
    group = "cloudflared";
  };

  age.identityPaths = [ "/home/chebuya/.ssh/id_ed25519" ];

  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  networking.hostName = "laptop"; # Define your hostname.
  networking.networkmanager.enable = true;

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

  users.users.chebuya = {
    isNormalUser = true;
    description = "Chebuya";
    extraGroups = [ "networkmanager" "wheel" "audio" ];
    packages = with pkgs; [
      firefox
    ];
  };
  
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "22.11";
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
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

  services.openssh = {
    enable = true;
    openFirewall = false;
    listenAddresses = [ { addr = "100.77.100.24"; port = 22; } { addr = "127.0.0.1"; port = 22; } ];
  };

  services.tailscale.enable = true;
  services.flatpak.enable = true;
  
  programs.command-not-found.enable = false;
  programs.fish.promptInit = ''
    any-nix-shell fish --info-right | source
  '';
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  environment.systemPackages = with pkgs; [
    pavucontrol
    qbittorrent-nox
    pasystray
    inputs.agenix.packages.x86_64-linux.default 
  ];

  hardware.opengl.driSupport32Bit = true;
  programs.steam.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8081 59100 34844 8888 ];
    allowedUDPPorts = [ 61385 59100 59200 64083 8888 ];
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
    checkReversePath = "loose";
  };

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

  users.users.shadowsocks = {
    group = "shadowsocks";
    isSystemUser = true;
  };
  users.groups.shadowsocks = {};

  systemd.services.swedenshadowsocks = {
    enable = true;
    description = "Shadowsocks";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5";
      User="shadowsocks";
      Group="shadowsocks";
    };
    script = ''
     password=$(cat "${config.age.secrets.sssweden.path}") 
     ss-local \
        -s "dreamykafe.tech" \
        -p 443 \
        -l 1080 \
        -b 0.0.0.0 \
        -k $password \
        -m "xchacha20-ietf-poly1305" \
        --plugin "v2ray-plugin" \
        --plugin-opts "tls;host=saltythunderingslugsached.dreamykafe.tech;path=/;loglevel=debug" \ 
        -t 300 \
        --reuse-port \
        --fast-open
    '';
    path = with pkgs; [ shadowsocks-libev shadowsocks-v2ray-plugin ];
  };

  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
  };
  users.groups.cloudflared = {};

  systemd.services.ssh_tunnel = {
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
     token=$(cat ${config.age.secrets.cloudflaredssh.path})
     cloudflared tunnel --no-autoupdate run --token=$token
    '';
    path = with pkgs; [ cloudflared ]; 
  };

  systemd.services.syncthing_tunnel = {
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
     token=$(cat ${config.age.secrets.cloudflaredsyncthing.path})
     cloudflared tunnel --no-autoupdate run --token=$token
    '';
    path = with pkgs; [ cloudflared ]; 
  };

  systemd.services.nginx_tunnel = {
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
     token=$(cat ${config.age.secrets.cloudflarednginx.path})
     cloudflared tunnel --no-autoupdate run --token=$token
    '';
    path = with pkgs; [ cloudflared ]; 
  };

  systemd.services.qbit_tunnel = {
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
     token=$(cat ${config.age.secrets.cloudflaredqbit.path})
     cloudflared tunnel --no-autoupdate run --token=$token
    '';
    path = with pkgs; [ cloudflared ]; 
  };

  users.users.qbit = {
    group = "qbit";
    isSystemUser = true;
    home = "/var/lib/qbittorrent-nox";
    createHome = true;
  };
  users.groups.qbit = {};
  
  systemd.services.qbitnox = {
    enable = true;
    description = "qbittorrent";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5";
      User="qbit";
      Group="qbit";
      WorkingDirectory="/var/lib/qbittorrent-nox";
    };
    path = with pkgs; [ qbittorrent-nox ];
    script = ''qbittorrent-nox'';
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

  systemd.services.nginx.serviceConfig = {
    SupplementaryGroups = [ "shadow" ];
    NoNewPrivileges = lib.mkForce false;
    PrivateDevices = lib.mkForce false;
    ProtectHostname = lib.mkForce false;
    ProtectKernelTunables = lib.mkForce false;
    ProtectKernelModules = lib.mkForce false;
    RestrictAddressFamilies = lib.mkForce [ ];
    LockPersonality = lib.mkForce false;
    MemoryDenyWriteExecute = lib.mkForce false;
    RestrictRealtime = lib.mkForce false;
    RestrictSUIDSGID = lib.mkForce false;
    SystemCallArchitectures = lib.mkForce "";
    ProtectClock = lib.mkForce false;
    ProtectKernelLogs = lib.mkForce false;
    RestrictNamespaces = lib.mkForce false;
    SystemCallFilter = lib.mkForce "";
    ProtectHome = lib.mkForce "read-only";
  };

  services.nginx.appendHttpConfig = ''
    disable_symlinks off;
  '';
}
