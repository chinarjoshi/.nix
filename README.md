I cannot express to you how happy these two files make me:

- **`configuration.nix`** - Full NixOS system configuration (requires root)
- **`home.nix`** - Portable home-manager configuration (works without root)

#### Initial Setup

1. Install Nix (if not already installed):
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

2. Add home-manager channel:
```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
nix-channel --update
```

3. Install home-manager:
```bash
nix-shell '<home-manager>' -A install
```

4. Copy config files:
```bash
# - ~/.config/nixos/home.nix
# - ~/.config/zsh/plugins/theme/.p10k.zsh
# - ~/.config/zsh/plugins/sudo.zsh
```

5. Apply config
```bash
home-manager switch -f ~/.config/nixos/home.nix
```

#### Updating Configuration

```bash
home-manager switch -f ~/.config/nixos/home.nix
```


In fact, run this step on any machine you have home manager to get shell, aliases, and tools.

### Rollback

**On NixOS:**
```bash
sudo nixos-rebuild --rollback
```

**Standalone home-manager:**
```bash
home-manager generations
home-manager switch --switch-generation <number>
```
