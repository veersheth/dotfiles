# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./hardware/nixos-hardware/framework/13-inch/7040-amd
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 6; # keeps 6 generations 

  boot.kernelParams = [ "kvm.enable_virt_at_load=0" ]; # virtualization(for COMP3431)

  networking.hostName = "framework-nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Suspend on power button press
  services.logind.extraConfig = ''
    HandlePowerKey=suspend
  '';

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.veer = {
    isNormalUser = true;
    description = "Veer";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # davinci-resolve
      ulauncher
      mixxx
      figma-linux
      spotify
      gimp3-with-plugins
      brave
      vscode
      obs-studio
      lazygit
      typst
      obsidian      	
      mpv
      pnpm_9 
      # nodejs_24 
      nodejs_20 
      zathura
      gnome-extension-manager
      alacritty kitty
      sshfs
      sox
    ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    bibata-cursors
    python313 python313Packages.pip
    bat
    pkg-config
    libnotify
    playerctl 
    jq
    xclip
    unzip
    git
    vim neovim
    wget
    gcc clang zig
    keyd
    openssl
    tree
    wget
    tmux
    stow
    fzf
    fd
    ripgrep
    gnome-tweaks
    cargo rustup rustc

    # for tauri 
    cargo-tauri
    at-spi2-atk atkmm cairo gdk-pixbuf glib
    gtk3 gtk3.dev  # Add this
    harfbuzz librsvg libsoup_3 pango
    webkitgtk_4_1 openssl pkg-config
    gobject-introspection xorg.libXtst


    # for hypr
    wl-clipboard copyq brightnessctl waybar dunst ulauncher hyprpaper hypridle 
    hyprlock hyprsunset hyprpicker hyprshot rofi-wayland hyprcursor cliphist
    networkmanagerapplet blueman ashell
  ];

  environment.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Ice"; 
    XCURSOR_SIZE = "24"; 
  };

  environment.etc."keyd/default.conf" = {
    source = files/keyd/default.conf;
  };

  users.defaultUserShell=pkgs.zsh; 
  users.users.veer.shell = pkgs.zsh; 
  
  programs = {
    firefox = {
      enable = true;
    };
    steam = {
      enable = true;
    };
    zsh = {
      enable = true;
      shellAliases = { cat = "bat"; };
    };
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    maple-mono.NF
    inter
    pkgs.helvetica-neue-lt-std
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # missing dynamic libraries for unpackaged programs here
  ];

  # List services that you want to enable:
  services = {
    keyd.enable = true;
    fprintd.enable = true;
    fprintd.tod.enable = true;
    fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;
    # flatpak.enable = true;
  };

  # Virtualization for COMP3431
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  users.extraGroups.vboxusers.members = [ "veer" ];

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}

