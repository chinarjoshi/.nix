{ pkgs, config, lib, ... }:

let
  # Claude Code also writes to this file, so merge keys in instead of owning it.
  setClaudeSettings = pkgs.writeShellScript "set-claude-settings" ''
    file="$HOME/.claude/settings.json"
    jq=${pkgs.jq}/bin/jq
    mkdir -p "$HOME/.claude"
    [ -f "$file" ] || echo '{}' > "$file"
    tmp=$(mktemp)
    $jq '.permissions.defaultMode = "bypassPermissions" | .skipDangerousModePermissionPrompt = true' \
      "$file" > "$tmp" && cat "$tmp" > "$file"
    rm -f "$tmp"
  '';
in
{
  home.stateVersion = "24.11";

  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${setClaudeSettings} || echo "warning: could not update the Claude settings" >&2
  '';

  # Use the system trust store, since uv's bundled CAs fail on TLS-intercepting networks.
  home.sessionVariables.UV_NATIVE_TLS = "1";

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Chinar Joshi";
        email = "chinarjoshi7@gmail.com";
      };
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      push.autoSetupRemote = true;
    };
  };

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
      export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
      export DOTFILES=$HOME/.config
      export EDITOR='nvim'
      export AUTOENV_ASSUME_YES='1'
      [ -f ~/.env ] && source ~/.env
    '';

    initContent = ''
      export HISTFILE=~/.histfile
      setopt appendhistory INC_APPEND_HISTORY SHARE_HISTORY PROMPT_SUBST autocd extended_glob
      unsetopt extended_history beep HIST_BEEP LIST_BEEP
      [ -f ~/.aliases.sh ] && . ~/.aliases.sh
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
      python = "python3";
    };
  };

  programs.kitty = {
    enable = true;
    font.name = "Inconsolata Nerd Font Mono";
    keybindings."f1" = "toggle_layout stack";
  };

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      tokyonight-nvim
      lualine-nvim
      gitsigns-nvim
      which-key-nvim
      telescope-nvim
      plenary-nvim
      blink-cmp
      conform-nvim
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

    initLua = ''
      require("config.options")
      require("config.keymaps")
      require("plugins.ui")
      require("plugins.telescope")
      require("plugins.completion")
      require("plugins.format")
      require("plugins.treesitter")
      require("config.lsp")
      require("config.leader")
    '';
  };

  xdg.configFile."nvim/lua".source = ./nvim/lua;
  xdg.configFile."nvim/.luarc.json".source = ./nvim/.luarc.json;

  home.packages = with pkgs; [
    btop
    cargo
    cmake
    fd
    fzf
    gcc
    git-lfs
    gnumake
    golangci-lint
    golines
    grpc
    grpcurl
    jq
    libiconv
    nerd-fonts.inconsolata
    nodejs
    pandoc
    fswatch
    pre-commit
    pyright
    ripgrep
    ruff
    tealdeer
    tree
    unzip
    uv
    wget
    yarn
    zip
    bun
    gh
    codex
    zellij
    obsidian
  ];
}
