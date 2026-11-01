{ config, lib, pkgs, ... }:

let
  glibtool = pkgs.runCommand "glibtool" {} ''
    mkdir -p $out/bin
    ln -s ${pkgs.libtool}/bin/libtool $out/bin/glibtool
    ln -s ${pkgs.libtool}/bin/libtoolize $out/bin/glibtoolize
  '';

  # Sets Reduce Motion through the private API behind the System Settings
  # toggle. Unlike `defaults write`, this notifies running processes. It turns
  # the setting off first because setting an unchanged value may not notify.
  setReduceMotion = pkgs.runCommandCC "set-reduce-motion" {
    src = pkgs.writeText "main.c" ''
      #include <dlfcn.h>
      #include <stdio.h>

      int main(void) {
        dlopen("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices", RTLD_NOW);
        void (*set)(int) = dlsym(RTLD_DEFAULT, "_AXInterfaceSetReduceMotionEnabled");
        int (*get)(void) = dlsym(RTLD_DEFAULT, "_AXInterfaceGetReduceMotionEnabled");
        if (!set || !get) {
          fprintf(stderr, "AXInterface Reduce Motion functions not found\n");
          return 1;
        }
        set(0);
        set(1);
        return (get() & 1) ? 0 : 1;
      }
    '';
  } ''
    mkdir -p $out/bin
    cc -x c -o $out/bin/set-reduce-motion $src
  '';

  # Level = log(factor) / log(1.2), so 0.5228 is 110%. Chrome rewrites its
  # profile on exit, so it has to be closed for the edit to stick. It only
  # stops and reopens with its tabs when the value needs changing.
  setChromeSettings = pkgs.writeShellScript "set-chrome-settings" ''
    prefs="$HOME/Library/Application Support/Google/Chrome/Default/Preferences"
    state="$HOME/Library/Application Support/Google/Chrome/Local State"
    jq=${pkgs.jq}/bin/jq
    [ -f "$prefs" ] && [ -f "$state" ] || exit 0
    [ "$($jq '.partition.default_zoom_level.x == 0.5228' "$prefs")" = true ] \
      && [ "$($jq '(.browser.enabled_labs_experiments // []) | index("enable-force-dark@1") != null' "$state")" = true ] \
      && exit 0

    running=0
    if /usr/bin/pgrep -x "Google Chrome" >/dev/null; then
      running=1
      /usr/bin/killall -TERM "Google Chrome"
      for _ in $(seq 40); do
        /usr/bin/pgrep -x "Google Chrome" >/dev/null || break
        /bin/sleep 0.5
      done
      if /usr/bin/pgrep -x "Google Chrome" >/dev/null; then
        echo "Chrome did not quit" >&2
        exit 1
      fi
    fi

    tmp=$(/usr/bin/mktemp)
    $jq '.partition.default_zoom_level.x = 0.5228' "$prefs" > "$tmp" && /bin/mv "$tmp" "$prefs"
    tmp=$(/usr/bin/mktemp)
    $jq '.browser.enabled_labs_experiments = (((.browser.enabled_labs_experiments // []) | map(select(startswith("enable-force-dark") | not))) + ["enable-force-dark@1"])' \
      "$state" > "$tmp" && /bin/mv "$tmp" "$state"
    if [ "$running" = 1 ]; then
      /usr/bin/open -a "/Applications/Google Chrome.app" --args --restore-last-session
    fi
  '';
in
{
  system.stateVersion = 5;
  system.primaryUser = "chijoshi";
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    casks = [ "rectangle" "hammerspoon" "karabiner-elements" "google-chrome" "kitty" ];
  };

  # Casks don't start apps or add login items.
  launchd.user.agents = lib.mapAttrs (_: app: {
    serviceConfig = {
      ProgramArguments = [ "/usr/bin/open" "-a" "/Applications/${app}.app" ];
      RunAtLoad = true;
    };
  }) {
    Rectangle = "Rectangle";
    Hammerspoon = "Hammerspoon";
    kitty = "kitty";
    chrome = "Google Chrome";
  };

  programs.zsh.enable = true;
  users.users.chijoshi.shell = pkgs.zsh;

  security.sudo.extraConfig = ''
    chijoshi ALL=(ALL) NOPASSWD: ALL
  '';

  # In units of 1/60s. Both are below the System Settings minimums (15 and 2).
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 10;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;

  # The driver's acceleration curve tops out at 3.0.
  system.defaults.".GlobalPreferences"."com.apple.mouse.scaling" = 2.5;
  system.defaults.NSGlobalDomain."com.apple.trackpad.scaling" = 2.5;

  # Animations
  system.defaults.NSGlobalDomain.NSAutomaticWindowAnimationsEnabled = false;
  system.defaults.NSGlobalDomain.NSScrollAnimationEnabled = false;
  system.defaults.NSGlobalDomain.NSUseAnimatedFocusRing = false;
  system.defaults.NSGlobalDomain.NSWindowResizeTime = 0.001;
  system.defaults.dock.autohide-delay = 0.0;
  system.defaults.dock.autohide-time-modifier = 0.0;
  system.defaults.dock.expose-animation-duration = 0.0;
  system.defaults.dock.launchanim = false;
  system.defaults.dock.mineffect = "scale";

  system.defaults.dock.autohide = true;
  system.defaults.dock.persistent-apps = [ ];
  system.defaults.dock.persistent-others = [ ];
  system.defaults.dock.show-recents = false;

  system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;

  system.defaults.CustomUserPreferences = {
    NSGlobalDomain = {
      NSToolbarFullScreenAnimationDuration = 0;
      NSBrowserColumnAnimationSpeedMultiplier = 0;
      NSDocumentRevisionsWindowTransformAnimation = false;
      QLPanelAnimationDuration = 0;
    };
    "com.apple.finder".DisableAllAnimations = true;
    "com.knollsoft.Rectangle" = {
      # keyCode 4 = h, modifierFlags 1179648 = cmd+shift
      leftHalf = {
        keyCode = 4;
        modifierFlags = 1179648;
      };
      # keyCode 37 = l
      rightHalf = {
        keyCode = 37;
        modifierFlags = 1179648;
      };
      # keyCode 36 = return, modifierFlags 1048576 = cmd
      maximize = {
        keyCode = 36;
        modifierFlags = 1048576;
      };
    };
    # Ctrl+1/2 switch spaces
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "118" = { enabled = true; value = { parameters = [49 18 262144]; type = "standard"; }; };
        "119" = { enabled = true; value = { parameters = [50 19 262144]; type = "standard"; }; };
      };
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.chijoshi = { config, lib, pkgs, ... }: {
    imports = [ ./common.nix ];

    home.username = "chijoshi";
    home.homeDirectory = lib.mkForce "/Users/chijoshi";

    # Installed by the Homebrew cask. Home Manager only writes the config.
    programs.kitty.package = null;
    programs.kitty.settings.font_size = 18;

    # These steps are best effort, so one failure can't abort the activation.
    home.activation.blackWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.desktoppr}/bin/desktoppr all "/System/Library/Desktop Pictures/Solid Colors/Black.png" \
        || echo "warning: could not set the desktop wallpaper" >&2
    '';

    # Applies input preferences without a new login.
    home.activation.activateSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u \
        || echo "warning: could not reload input settings" >&2
    '';

    # `schedule start` means sunset to sunrise.
    home.activation.nightShift = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.nightlight}/bin/nightlight schedule start \
        || echo "warning: could not set the Night Shift schedule" >&2
    '';

    # macOS may ask for confirmation the first time this changes the default.
    home.activation.defaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.defaultbrowser}/bin/defaultbrowser chrome \
        || echo "warning: could not set the default browser" >&2
    '';

    home.activation.chromeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${setChromeSettings} || echo "warning: could not apply the Chrome settings" >&2
    '';

    # Rectangle only reads its shortcuts at launch.
    home.activation.restartRectangle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run /usr/bin/killall Rectangle || true
      run /usr/bin/open -a /Applications/Rectangle.app \
        || echo "warning: could not restart Rectangle" >&2
    '';

    home.activation.reduceMotion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${setReduceMotion}/bin/set-reduce-motion \
        || echo "warning: could not enable Reduce Motion" >&2
    '';

    home.file.".config/karabiner/karabiner.json".text = builtins.toJSON {
      global.check_for_updates_on_startup = false;
      profiles = [{
        name = "Default";
        selected = true;
        virtual_hid_keyboard.keyboard_type_v2 = "ansi";
        complex_modifications.rules = [
          {
            description = "Caps Lock → Escape (tap) / Left Control (hold)";
            manipulators = [{
              type = "basic";
              from = {
                key_code = "caps_lock";
                modifiers.optional = [ "any" ];
              };
              to = [{ key_code = "left_control"; lazy = true; }];
              to_if_alone = [{ key_code = "escape"; }];
            }];
          }
          {
            description = "Ctrl+K → Cmd+K";
            manipulators = [{
              type = "basic";
              from = {
                key_code = "k";
                modifiers = {
                  mandatory = [ "control" ];
                  optional = [ "caps_lock" ];
                };
              };
              to = [{
                key_code = "k";
                modifiers = [ "left_command" ];
              }];
            }];
          }
        ];
      }];
    };

    home.file.".hammerspoon/init.lua".text = ''
      -- Cmd+h/j/l focus the neighboring window and move the mouse to its center
      local dirMap = {
        h = "West",
        j = "South",
        l = "East",
      }

      for key, dir in pairs(dirMap) do
        hs.hotkey.bind({"cmd"}, key, function()
          local win = hs.window.focusedWindow()
          if not win then return end

          local method = "focusWindow" .. dir
          win[method](win)

          local win = hs.window.focusedWindow()
          local f = win:frame()
          hs.mouse.setAbsolutePosition({
            x = f.x + f.w/2,
            y = f.y + f.h/2,
          })
        end)
      end
    '';

    programs.zsh.shellAliases = {
      rebuild = "sudo darwin-rebuild switch --flake '${config.home.homeDirectory}/.nix#mac'";
    };

    programs.zsh.initContent = ''
      unsetopt BEEP
      unsetopt HIST_BEEP
      unsetopt LIST_BEEP
      export LIBRARY_PATH="/opt/homebrew/lib/gcc/current''${LIBRARY_PATH:+:$LIBRARY_PATH}"
      export PATH="/opt/homebrew/bin:/opt/homebrew/opt/go@1.22/bin:$PATH"
      export SSH_SK_PROVIDER=/usr/local/lib/sk-libfido2.dylib
      [ -f ~/.aliases.sh ] && . ~/.aliases.sh
    '';
  };

  environment.systemPackages = [
    pkgs.libtool
    glibtool
  ];
}
