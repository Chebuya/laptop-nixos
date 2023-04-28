{ inputs, config, pkgs, lib, ...}:
{
  age.secrets.sssweden = {
    file = ./secrets/sssweden.age;
    owner = "shadowsocks";
    group = "shadowsocks";
  };

  age.secrets.ssfinland = {
    file = ./secrets/ssfinland.age;
    owner = "shadowsocks";
    group = "shadowsocks";
  };

  age.secrets.cloudflarednginx = {
    file = ./secrets/cloudflarednginx.age;
    owner = "cloudflared";
    group = "cloudflared";
  };

  age.secrets.cloudflaredinternal = {
    file = ./secrets/cloudflaredinternal.age;
    owner = "cloudflared";
    group = "cloudflared";
  };

  age.secrets.cloudflaredssh = {
    file = ./secrets/cloudflaredssh.age;
    owner = "cloudflared";
    group = "cloudflared";
  };

  age.secrets.precise = {
    file = ./secrets/precise.age;
    owner = "chebuya";
    group = "users";
  };

  age.identityPaths = [ "/home/chebuya/.ssh/id_ed25519" ];

  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
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

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    listenAddresses = [ { addr = "100.77.100.24"; port = 22; } { addr = "127.0.0.1"; port = 22; } ];
  };

  services.haste-server = {
    enable = true;
  };

  services.tailscale.enable = true;
  services.flatpak.enable = true;
  programs.firejail.enable = true; 
  programs.command-not-found.enable = false;
  programs.fish.promptInit = ''
    any-nix-shell fish --info-right | source
  '';
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  environment.etc."fuckwg" = {
    mode = "0555";
    text = ''
      #!/bin/sh
      sudo ip rule del fwmark 100 table 100
      sudo ip rule add fwmark 100 table 100
    '';
  };

  environment.systemPackages = with pkgs; [
    firejail
    traceroute
    pavucontrol
    pasystray
    inputs.agenix.packages.x86_64-linux.default 
  ];

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

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
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

  users.users.qbit = {
    group = "users";
    isSystemUser = true;
    createHome = true;
    home = "/var/lib/qbit";
  };

  systemd.services.defaultgateway = {
    enable = false;
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type="oneshot";
      RemainAfterExit="true";
    };
    script = ''
      NETNS="/var/run/netns/netns0"
      if [ -f "$NETNS" ]; then
        echo "netns0 exists"
      else
        echo "creating netns0..."
        ip netns add netns0
        ip link add veth0 type veth peer name veth1
        ip link set veth1 netns netns0
        ip addr add 10.0.0.1/24 dev veth0
        ip link set veth0 up
        ip netns exec netns0 ip addr add 10.0.0.2/24 dev veth1
        ip netns exec netns0 ip link set veth1 up
        ip netns exec netns0 ip route add default via 10.0.0.1
        sysctl -w net.ipv4.ip_forward=1
        iptables -t nat -A POSTROUTING -o wlp1s0 -j MASQUERADE
        ip rule add fwmark 100 table 100 
        ip rule add from 10.0.0.2 table 100
        ip netns exec netns0 iptables -t mangle -A OUTPUT -o veth0 -j MARK --set-mark 100
        ip route add default via 192.168.50.1 dev wlp1s0 table 100
        echo "netns0 created"
      fi
    '';
    path = with pkgs; [ iproute2 sysctl iptables];
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
#      PrivateNetwork = true;
#      NetworkNamespacePath = "/var/run/netns/netns0";
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
        -b 127.0.0.1 \
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

  systemd.services.finlandshadowsocks = { 
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
     password=$(cat "${config.age.secrets.ssfinland.path}") 
     ss-local \
        -s "fin.dreamykafe.tech" \
        -p 443 \
        -l 1081 \
        -b 127.0.0.1 \
        -k $password \
        -m "xchacha20-ietf-poly1305" \
        --plugin "v2ray-plugin" \
        --plugin-opts "tls;host=fin.dreamykafe.tech;path=/socks;loglevel=debug" \ 
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

  systemd.services.internal_tunnel = {
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
     token=$(cat ${config.age.secrets.cloudflaredinternal.path})
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
    locations."/syncthing".extraConfig = ''
      proxy_set_header        Host localhost;
      proxy_set_header        Referer  http://syncthing:8384;
      proxy_set_header        X-Real-IP $remote_addr;
      proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto $scheme;
      proxy_pass              http://localhost:8384/;
      add_header X-Content-Type-Options "nosniff";
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
