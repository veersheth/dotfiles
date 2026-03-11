# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 6; # keeps 6 generations 

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "hid_sensor_hub" ];

  networking.hostName = "framework-nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Sydney";
  # time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
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
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "au";
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

  hardware.sensor.iio.enable = true; # for autobrightness

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.veer = {
    isNormalUser = true;
    description = "Veer";
    # extraGroups = [ "networkmanager" "wheel" ];
    extraGroups = [ "networkmanager" "wheel" "video" "docker" ]; 
    packages = with pkgs; [
      # Apps
      discord
      docker
      rquickshare
      zathura sioyek
      brave
      gimp3
      spotify
      tor-browser
      obsidian
      alacritty
      lazygit
      mpv
      ghostty
      davinci-resolve
      kdePackages.kdenlive
      vscode
      livecaptions
      obs-studio
      gnome-extension-manager
      shotcut
      figma-linux
      syncthing
      zoom-us
      libreoffice
      p3x-onenote

      # CLI
      sshfs
      typst texlive.combined.scheme-full
      pnpm_9 nodejs_20
      docker_25
      tree-sitter

      # GNOME Extensions
      gnomeExtensions.bluetooth-battery-meter 
      gnomeExtensions.live-captions-assistant
      gnomeExtensions.gsconnect 
      gnomeExtensions.impatience 
      gnomeExtensions.just-perfection 
      gnomeExtensions.caffeine
      gnomeExtensions.appindicator

      # Hyprland
      hyprpanel
      hypridle 
      hyprlock
      hyprsunset
      hyprpaper
      hyprshot
      hyprpicker

    ];
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;

  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
    snapshot
  ]);

  users.defaultUserShell=pkgs.zsh; 
  users.users.veer.shell = pkgs.zsh;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      inter
      helvetica-neue-lt-std
      junicode
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.iosevka
      agave
      maple-mono.NF
      cascadia-code
      
      whatsapp-emoji-font
      noto-fonts-emoji
      noto-fonts-color-emoji
    ];
    
    fontconfig = {
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  programs = {
    nix-ld.enable = true;
    firefox = {
      enable = true;
    };
    # steam = {
    #   enable = true;
    # };
    zsh = {
      enable = true;
      shellAliases = { cat = "bat"; };
    };
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    neovim = {
      defaultEditor = true;
    };
    kdeconnect = {
      enable = true;
      package = pkgs.gnomeExtensions.gsconnect;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    brightnessctl
    python313 python313Packages.pip
    bat
    pkg-config
    libnotify
    playerctl 
    jq
    xclip wl-clipboard
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
    cargo rustc
    bibata-cursors
  ];

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  environment.etc."keyd/default.conf" = {
    source = files/keyd/default.conf;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services = {
    # timesyncd.enable = true;
    fwupd.enable = true;
    keyd.enable = true;
    fprintd.enable = true;
    flatpak.enable = true;
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
      percentageLow = 10;
      percentageCritical = 5;
      percentageAction = 2;
    };
     syncthing = {
      enable = true;
      openDefaultPorts = true; # Open ports in the firewall for Syncthing. (NOTE: this will not open syncthing gui port)
    };
  };


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

