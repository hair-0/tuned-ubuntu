#!/bin/sh
# run_once_03-neovim.sh — 首次部署：克隆 neovim 配置（独立仓库）。
# ~/.config/nvim 本身就是 hair-0/neovim-config 的 git 工作区，
# 因此不纳入 chezmoi 管理（见 .chezmoiignore）。
set -e

NVIM_CFG="$HOME/.config/nvim"

if [ ! -d "$NVIM_CFG/.git" ]; then
    if [ -e "$NVIM_CFG" ]; then
        echo "警告: $NVIM_CFG 已存在且不是 git 仓库，跳过克隆，请手动处理。"
    else
        git clone --depth 1 https://github.com/hair-0/neovim-config.git "$NVIM_CFG"
    fi
else
    echo "已存在: $NVIM_CFG"
fi

if command -v nvim >/dev/null 2>&1; then
    echo "==> 按 lazy-lock.json 恢复插件（可能较慢）"
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || true
fi
echo "==> neovim 配置完成"
