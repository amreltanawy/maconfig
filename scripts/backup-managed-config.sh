#!/usr/bin/env bash
# Move existing home paths aside before home-manager activation would clobber them.
# Sourced by bootstrap.sh and rebuild.sh.

backup_managed_config() {
  local repo_dir="$1"
  local backup_root="$repo_dir/backup_config"

  # Paths home-manager manages in home.nix (symlinks + programs.zsh).
  # .zprofile is included because its usual contents (PATH entries, nvm)
  # are provided by home.nix now; a leftover copy would load things twice.
  local paths=(
    .config/nvim
    .config/wezterm
    .config/herdr
    .claude/settings.json
    .zshrc
    .zprofile
  )

  local rel target dest link dest_dir backed_up=false

  for rel in "${paths[@]}"; do
    target="$HOME/$rel"
    [[ -e "$target" || -L "$target" ]] || continue

    if [[ -L "$target" ]]; then
      link="$(readlink "$target")"
      # Skip links that already point at this repo, and links home-manager
      # itself created (they point into /nix/store); backing those up would
      # move our own managed config aside on every rebuild.
      if [[ "$link" == "$repo_dir/"* ]] || [[ "$link" == "$HOME/.maconfig/"* ]] || [[ "$link" == /nix/store/* ]]; then
        continue
      fi
    elif [[ "$rel" == ".zshrc" && -f "$target" ]]; then
      if grep -q 'Home Manager start' "$target" 2>/dev/null; then
        continue
      fi
    fi

    dest="$backup_root/$rel"
    if [[ -e "$dest" || -L "$dest" ]]; then
      dest="${dest}.$(date +%Y%m%d-%H%M%S)"
    fi
    dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"
    mv "$target" "$dest"
    echo "    backed up ~/$rel -> ${dest#"$repo_dir"/}"
    backed_up=true
  done

  if $backed_up; then
    echo "    previous configs saved under $backup_root"
  fi
}
