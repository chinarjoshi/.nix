{ pkgs, config, ... }:

let
  # sioyek reads ~/.config/sioyek AND the platform-native config dir, loading
  # the latter second so it wins. Target the one that actually takes effect
  # rather than relying on that precedence.
  sioyekPrefs =
    if pkgs.stdenv.isDarwin
    then "Library/Application Support/sioyek/prefs_user.config"
    else ".config/sioyek/prefs_user.config";
in
{
  home.stateVersion = "24.11";

  # uv ships its own bundled CA store, which does not contain the corporate
  # root CA used for TLS interception -- every fetch from pypi fails with
  # `invalid peer certificate: UnknownIssuer`. This makes uv use the macOS
  # keychain instead, so it stays correct as IT rotates the CA.
  home.sessionVariables.UV_NATIVE_TLS = "1";

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      light = false;
      line-numbers = true;
    };
  };

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    envExtra = ''
      export PATH="/opt/homebrew/opt/go@1.22/bin:$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin:$PATH"
      export DOTFILES=$HOME/.config
      export EDITOR='nvim'
      export AUTOENV_ASSUME_YES='1'
      [ -f ~/.env ] && source ~/.env
    '';

    initContent = ''
      export HISTFILE=~/.histfile
      setopt appendhistory INC_APPEND_HISTORY SHARE_HISTORY PROMPT_SUBST autocd extended_glob
      unsetopt extended_history beep
      autoload -Uz compinit && compinit
      zstyle ':completion:*' matcher-list ''' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

      ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
      typeset -A ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=white

      PROMPT='%F{blue}''${''${''${PWD/#''$HOME/}#/}:-.}%f
''$ '

      bindkey -e
      autoload -Uz select-word-style
      select-word-style bash
      zstyle ':zle:backward-kill-word' word-style whitespace

      backward-kill-bash-word() {
        local WORDCHARS='''
        zle .backward-kill-word
      }
      zle -N backward-kill-bash-word
      bindkey '^[^?' backward-kill-bash-word

      autoload -Uz edit-command-line
      zle -N edit-command-line
      bindkey '^X^E' edit-command-line

      echo -e '\e[6 q'

      mp4() {
        if [ -z "$1" ]; then
          echo "Usage: mp4 <input.mov>"
          return 1
        fi
        local output="''${1%.*}.mp4"
        ffmpeg -i "$1" -c:v libx264 -crf 23 -c:a aac -b:a 128k "$output"
      }

      html() {
        if [ -z "$1" ]; then
          echo "Usage: html <input.md>"
          return 1
        fi
        local input="$1"
        local output="''${1%.*}.html"
        pandoc -s "$input" -o "$output"
        echo "Watching $input → $output (Ctrl-C to stop)"
        fswatch -o "$(dirname "$input")" | while read; do
          if [ "$input" -nt "$output" ]; then
            pandoc -s "$input" -o "$output" && echo "↻ $output"
          fi
        done
      }

    '';

    plugins = [{
      name = "zsh-syntax-highlighting";
      src = pkgs.zsh-syntax-highlighting;
      file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
    }];

    shellAliases = {
      ga = "git add";
      gau = "git add -u";
      gc = "git commit";
      gC = "git commit --amend --no-edit";
      gd = "git diff -- . ':!*.sql.go' ':!*.pb.go' ':!db.go'";
      gch = "git checkout";
      gchb = "git checkout -b";
      gsh = "git show";
      gshh = "git show HEAD~";
      gl = "git log -n15";
      gll = "git log";
      gpu = "git push";
      gpuf = "git push -f";
      grh = "git reset --hard";
      gs = "git status";
      gpl = "git pull";
      gf = "git fetch";
      gdh = "git diff HEAD~";
      gds = "git diff --staged -- . ':!*.sql.go' ':!*.pb.go' ':!db.go'";
      gst = "git stash";
      gsta = "git stash apply";
      gstd = "git stash drop";
      gstp = "git stash pop";
      gb = "git branch";
      gba = "git branch --all";
      gm = "git merge";
      gr = "git rebase";
      gra = "git rebase --abort";
      grc = "git rebase --continue";
      gri = "git rebase -i";
      gss = "git status -suno";
      gdn = "git diff --name-only";
      gres = "git restore";
      l = "ls -lAFgG --color=auto";
      c = "claude --dangerously-skip-permissions";
      cr = "claude --dangerously-skip-permissions --resume";
      cc = "claude --dangerously-skip-permissions --continue";
      python = "python3";
      music = "cd ~/.local/share/org.gnome.SoundRecorder";
    };
  };

  programs.kitty = {
    enable = true;
    settings = {
      macos_option_as_alt = "yes";
    };
    keybindings = {
      "opt+b" = "send_text all \\x1bb";
      "opt+f" = "send_text all \\x1bf";
      "f1" = "toggle_layout stack";
    };
  };

  # Neovim. Plugins come from nixpkgs rather than lazy.nvim; the setup bodies
  # that used to live inside lazy specs are now plain modules in nvim/lua/plugins.
  # Everything loads at startup -- the old `event = "VeryLazy"` / `cmd = ...`
  # deferral is gone, which costs a few ms and buys reproducibility.
  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      tokyonight-nvim
      lualine-nvim
      gitsigns-nvim
      which-key-nvim
      telescope-nvim
      plenary-nvim # was a telescope `dependencies` entry
      blink-cmp # Rust fuzzy matcher is built by the derivation, no download
      friendly-snippets # was a blink.cmp `dependencies` entry
      conform-nvim
      # Grammars are pinned here instead of `ensure_installed` + `:TSInstall`.
      # Adding a language = add it to this list and rebuild.
      (nvim-treesitter.withPlugins (p: with p; [
        bash
        json
        lua
        markdown
        markdown_inline
        nix
        python
        query
        toml
        vim
        vimdoc
        yaml
      ]))
    ];

    # The old init.lua, minus `require("config.lazy")`. Plugins are already on
    # the packpath by the time this runs, so load order is just require order.
    initLua = ''
      require("config.options")
      require("config.keymaps")
      require("plugins.ui")
      require("plugins.telescope")
      require("plugins.completion")
      require("plugins.format")
      require("plugins.treesitter")
      require("config.lsp")
    '';
  };

  # Symlinked as a tree rather than inlined into extraLuaConfig so the modules
  # stay real .lua files that lua_ls can attach to.
  xdg.configFile."nvim/lua".source = ./nvim/lua;
  xdg.configFile."nvim/.luarc.json".source = ./nvim/.luarc.json;

  # Only prefs_user.config is declarative. sioyek also writes auto.config
  # (window geometry) and three sqlite DBs into the same directory, so the
  # directory itself has to stay mutable -- never symlink the whole thing.
  home.file.${sioyekPrefs}.source = ./sioyek/prefs_user.config;

  home.packages = with pkgs; [
    arp-scan
    arping
    btop
    cargo
    clang-tools
    cmake
    dbmate
    fd
    fzf
    gcc
    git-lfs
    gnumake
    golangci-lint
    golines
    gopls
    grpc
    grpcurl
    inter
    jq
    libiconv
    libpq
    lua-language-server
    nerd-fonts.inconsolata
    nmap
    nodePackages.bash-language-server
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.yaml-language-server
    nodejs
    pandoc
    fswatch
    pdsh
    postgresql_14
    pre-commit
    pyright
    ripgrep
    ruff
    sioyek
    sqlc
    squashfsTools
    taplo
    tealdeer
    tree
    unzip
    uv
    wget
    yarn
    zip
    bun
    gh
    zellij
    obsidian
  ];
}
