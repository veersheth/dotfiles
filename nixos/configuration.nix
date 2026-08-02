# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      <nixos-hardware/framework/13-inch/7040-amd>
      ./hardware-configuration.nix
    ];

  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs-unstable"
    "nixos-config=/home/veer/dotfiles/nixos/configuration.nix"
  ];

  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 7d"; };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 6; # keeps 6 generations 

  zramSwap.enable = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [
    "hid_sensor_hub" # for autobrightness
    "kvm-amd"
  ];
  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "amdgpu.sg_display=0"
  ];

  hardware.graphics.enable32Bit = true; # for lutris

  networking.hostName = "nixos"; # Define your hostname.
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

  # GNOME
  services.xserver.enable = true;
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # # COSMIC
  # services.xserver.enable = true; 
  # services.displayManager.cosmic-greeter.enable = true;
  # services.desktopManager.cosmic.enable = true;
  # services.system76-scheduler.enable = true;

  # # XFCE
  # services.xserver = {
  #   enable = true;
  #   desktopManager = {
  #     xterm.enable = false;
  #     xfce.enable = true;
  #   };
  # };
  # services.displayManager.defaultSession = "xfce";

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
      # GUI 
      gimp-with-plugins
      steam lutris wine winetricks
      blender
      spotify spotatui
      sioyek mupdf
      tor-browser
      obsidian
      mpv
      kitty alacritty
      vscode android-studio
      brave 
      livecaptions
      obs-studio
      onlyoffice-desktopeditors
      keepass


      # CLI
      marp-cli
      lazygit
      figlet
      imagemagick
      luajitPackages.magick
      sshfs
      typst texlive.combined.scheme-full
      pnpm nodejs_22
      docker_25
      btop powertop
      bun
      claude-code


      # # GNOME 
      gnome-tweaks
      gnomeExtensions.media-controls
      gnomeExtensions.rounded-window-corners-reborn
      gnomeExtensions.user-themes
      gnomeExtensions.disable-workspace-animation
      gnomeExtensions.bluetooth-battery-meter 
      gnomeExtensions.gsconnect 
      gnomeExtensions.impatience 
      gnomeExtensions.disable-workspace-animation
      gnomeExtensions.just-perfection 
      gnomeExtensions.caffeine
      gnomeExtensions.appindicator
      #
    ];
  };

  users.defaultUserShell=pkgs.zsh; 
  users.users.veer.shell = pkgs.zsh;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      liberation_ttf
      inter
      helvetica-neue-lt-std
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
      
      noto-fonts-color-emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Inter" ];
        # sansSerif = [ "Inter" ];
      };
    };
  };


  programs = {
    appimage = { enable = true; binfmt = true; package = pkgs.appimage-run.override { extraPkgs = pkgs: [ pkgs.libthai ]; }; };

    nix-ld = { enable = true; };
    nix-ld.libraries = with pkgs; [ stdenv.cc.cc zlib fuse3 icu nss openssl curl expat ];

    firefox = { enable = true; };

    steam = { enable = true; };
    gamemode = { enable = true; };

    zsh = { enable = true; };

    neovim = { 
      enable = true;
      defaultEditor = true;
    };

    java = { enable = true; };

    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    kdeconnect = {
      enable = true;
      package = pkgs.kdePackages.kdeconnect-kde;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    zenity
    tree-sitter
    ffmpeg
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
    yazi
    wget
    tmux
    stow
    fzf
    fd
    ripgrep
    rustup cargo rustc clippy
    bibata-cursors
    framework-tool


    # hyprland
    hyprland hypridle hyprpicker hyprsunset hyprpolkitagent 
    hyprshot cliphist satty

    hyprlock 

    quickshell
    qt5.qtgraphicaleffects
  ];

  environment.etc."keyd/default.conf" = {
    source = files/keyd/default.conf;
  };

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  services = {
    # timesyncd.enable = true;
    fwupd.enable = true;
    keyd.enable = true;
    fprintd.enable = true;
    flatpak.enable = true;
    logind = {
      powerKey = "suspend";
      lidSwitch = "suspend";
      lidSwitchExternalPower = "suspend"; 
    };
    upower = {
      enable = true;
      criticalPowerAction = "PowerOff";
    };
    syncthing = {
      enable = true;
      user = "veer";      
      group = "users";         
      dataDir = "/home/veer";
      configDir = "/home/veer/.config/syncthing";
      openDefaultPorts = true;    
    };
  };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

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
