#!/bin/sh
# Run once per machine by `chezmoi apply`: install oh-my-zsh plus the
# third-party plugins and powerlevel10k theme referenced from ~/.zshrc.
# They are upstream git repos, so they are re-cloned instead of being
# tracked in this dotfiles repository.
set -e

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

OMZ_CUSTOM="${ZDOTDIR:-$HOME}/.oh-my-zsh/custom"

clone_into() {
  repo=$1
  target=$2
  if [ ! -d "$OMZ_CUSTOM/$target" ]; then
    git clone --depth 1 "https://github.com/$repo" "$OMZ_CUSTOM/$target"
  fi
}

clone_into zsh-users/zsh-autosuggestions        plugins/zsh-autosuggestions
clone_into zsh-users/zsh-completions            plugins/zsh-completions
clone_into zsh-users/zsh-syntax-highlighting    plugins/zsh-syntax-highlighting
clone_into romkatv/powerlevel10k                themes/powerlevel10k
