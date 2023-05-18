# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.kernelParams = ["quiet"];
  boot.initrd.availableKernelModules = [ "kvm-amd" "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" "nvme" "xhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.initrd.luks = {
    yubikeySupport = true;
    devices."cryptroot" = {
      device = "/dev/nvme0n1p2";
      yubikey.storage.device = "/dev/nvme0n1p1";
    };
  };
  boot.kernelModules = [ "usbip" "kvm-amd" "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" "nvme" "xhci_pci" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.usbip.out ];
  boot.kernelPackages = pkgs.linuxPackages_zen;
  hardware.bluetooth.enable = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/f650daf8-6b92-4a0b-83d7-94b64d4dd189";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/58B4-7151";
      fsType = "vfat";
    };

 swapDevices = [ {
   device = "/var/lib/swapfile";
   size = 8*1024;
 } ];

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
