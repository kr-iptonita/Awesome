{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (inputs.nix-colors.lib-contrib {inherit pkgs;}) nixWallpaperFromScheme;

  # use OCR and copy to clipboard
  ocrScript = let
    inherit (pkgs) grim libnotify slurp tesseract5 wl-clipboard;
    _ = lib.getExe;
  in
    pkgs.writeShellScriptBin "wl-ocr" ''
      ${_ grim} -g "$(${_ slurp})" -t ppm - | ${_ tesseract5} - - | ${wl-clipboard}/bin/wl-copy
      ${_ libnotify} "$(${wl-clipboard}/bin/wl-paste)"
    '';
in {
  imports = [
    inputs.hyprland.homeManagerModules.default

    ../../dunst
    ../../waybar
    ../../gtk.nix
    ../../rofi.nix
    ../../swaylock.nix
  ];

  home = {
    packages = with pkgs; [
      clipman
      grim
      ocrScript
      pngquant
      python39Packages.requests
      slurp
      swayidle
      tesseract5
      wf-recorder
      wl-clipboard
      xorg.xprop
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      inputs.hyprpicker.packages.${pkgs.system}.hyprpicker
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      DISABLE_QT5_COMPAT = "0";
      ANKI_WAYLAND = "1";
      DIRENV_LOG_FORMAT = "";
      WLR_DRM_NO_ATOMIC = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      GDK_BACKEND = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_STYLE_OVERRIDE = "kvantum";
      MOZ_ENABLE_WAYLAND = "1";
      WLR_BACKEND = "vulkan";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
      XCURSOR_SIZE = "24";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default.override {
      nvidiaPatches = true;
      wlroots =
        inputs.hyprland.packages.${pkgs.system}.wlroots-hyprland.overrideAttrs
        (old: {
          patches =
            (old.patches or [])
            ++ [
              (pkgs.fetchpatch {
                url = "https://aur.archlinux.org/cgit/aur.git/plain/0001-nvidia-format-workaround.patch?h=hyprland-nvidia-screenshare-git";
                sha256 = "A9f1p5EW++mGCaNq8w7ZJfeWmvTfUm4iO+1KDcnqYX8=";
              })
            ];
        });
    };
    systemdIntegration = true;
    extraConfig = import ./config.nix {
      inherit (config) colorscheme;
    };
  };

  services.gammastep = {
    enable = true;
    provider = "geoclue2";
  };

  systemd.user.services.swaybg = let
    wallpaper = nixWallpaperFromScheme {
      scheme = config.colorscheme;
      width = 3072;
      height = 1920;
      logoScale = 6.0;
    };
  in {
    Unit = {
      Description = "Wayland wallpaper daemon";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg --mode fill --image ${wallpaper}";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
