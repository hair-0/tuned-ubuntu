#!/bin/sh
# run_once_02-assets.sh — 首次部署：下载不入 git 的第三方资产（光标、Nerd 字体）。
# 主题类小文件（Catppuccin 配色、Konsole 方案、Kvantum、fcitx5 主题、KZones）
# 已直接收录在本仓库中，由 chezmoi apply 自动落盘。
set -e

FONTS="$HOME/.local/share/fonts"
ICONS="$HOME/.local/share/icons"
mkdir -p "$FONTS" "$ICONS"

fetch() {
    echo "下载: $1"
    curl -fSL --retry 5 --retry-delay 3 --retry-all-errors -o "$2" "$1"
}

# ---- Bibata 光标 v2.0.7 ----
if [ ! -d "$ICONS/Bibata-Modern-Classic" ]; then
    tmp=$(mktemp -d)
    fetch "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz" "$tmp/bibata.tar.xz"
    tar -xf "$tmp/bibata.tar.xz" -C "$ICONS"
    rm -rf "$tmp"
else
    echo "已存在: Bibata-Modern-Classic"
fi

# ---- Nerd Fonts（终端/编辑器图标字体）----
install_nerd_font() {
    dir_name=$1
    zip_name=$2
    if [ -d "$FONTS/$dir_name" ]; then
        echo "已存在: $dir_name"
        return 0
    fi
    tmp=$(mktemp -d)
    fetch "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${zip_name}.zip" "$tmp/${zip_name}.zip"
    mkdir -p "$FONTS/$dir_name"
    unzip -oq "$tmp/${zip_name}.zip" -d "$FONTS/$dir_name"
    rm -rf "$tmp"
}
install_nerd_font FiraCodeNerdFont FiraCode
install_nerd_font JetBrainsMonoNerdFont JetBrainsMono

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONTS" >/dev/null 2>&1 || true
fi
echo "==> 资产安装完成"
