{
  =inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #hyprland.url = "github:hyprwm/Hyprland";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # outputs = { nixpkgs, home-manager, ...}: {
  #   nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
  #     system = "x86_64-linux";
  #     modules = [
  #       ./configuration.nix
  #       home-manager.nixosModules.home-manager
  #       { 
  #         home-manager.useGlobalPkgs = true;
  #         home-manager.useUserPackages = true;
  #         home-manager.users.chebuya = import ./home.nix;
  #       }
  #     ];
  #   };
  # };
  outputs = { self, nixpkgs, home-manager }:
    let
      # ...
    in {
      nixosModules = {
        system = { pkgs, ... }: {
          config = {
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
            hardware.pulseaudio.enable = true;
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
 
            services.flatpak.enable = true;          
            programs.fish.promptInit = ''
              any-nix-shell fish --info-right | source
            '';
            programs.fish.enable = true;
            users.defaultUserShell = pkgs.fish;
            xdg.portal.enable = true;
            xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
            #services.xserver.displayManager.autoLogin.enable = true;
#            services.xserver.displayManager.autoLogin.user = "chebuya";
#            services.xserver.displayManager.gdm.wayland = false;
#            services.xserver.enable = true;
#            services.xserver.displayManager.gdm.enable = true;
#            services.xserver.desktopManager.gnome.enable = true;
#            systemd.services."getty@tty1".enable = false;
#            systemd.services."autovt@tty1".enable = false;
            #environment.gnome.excludePackages = (with pkgs; [
            #  gnome-tour
            #]) ++ (with pkgs.gnome; [
            #  cheese # webcam tool
            #  epiphany # web browser
            #  gnome-characters
            #  tali # poker game
            #  iagno # go game
            #  hitori # sudoku game
            #  atomix # puzzle game
            #  yelp # Help view
            #  gnome-initial-setup
            #]);
            #programs.dconf.enable = true;
            environment.systemPackages = with pkgs; [
              pavucontrol
            ];
          };
        };
      };

      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = with self.nixosModules; [
          ./hardware.nix
          system
          home-manager.nixosModules.home-manager
          { 
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.chebuya = import ./home.nix;
          }
        ];
      };
    };
}
