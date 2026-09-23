#!/bin/sh
# run_once_01-snap-flatpak.sh — 首次部署：安装 snap 与 flatpak 应用。
set -e

SRC="${CHEZMOI_SOURCE_DIR:?CHEZMOI_SOURCE_DIR 未设置，请通过 chezmoi apply 运行}"

if command -v snap >/dev/null 2>&1; then
    echo "==> 安装 snap 应用"
    while read -r name flag; do
        case "$name" in ''|\#*) continue ;; esac
        if snap list "$name" >/dev/null 2>&1; then
            echo "已安装: $name"
            continue
        fi
        # shellcheck disable=SC2086
        sudo snap install "$name" $flag || echo "警告: $name 安装失败，稍后手动处理"
    done < "$SRC/manifests/snaps.txt"
fi

if command -v flatpak >/dev/null 2>&1; then
    echo "==> 配置 flatpak 并安装应用"
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    while read -r remote app; do
        case "$app" in ''|\#*) continue ;; esac
        sudo flatpak install -y "$remote" "$app" || echo "警告: $app 安装失败，稍后手动处理"
    done < "$SRC/manifests/flatpaks.txt"
fi
echo "==> snap / flatpak 完成"
