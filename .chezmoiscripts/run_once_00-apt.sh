#!/bin/sh
# run_once_00-apt.sh — 首次部署：添加第三方 APT 源并安装软件清单。
# 由 `chezmoi apply` 在每台新机器上执行一次；内容变化时会重新执行。
# 需要网络（GitHub / 微软 / Launchpad / 清华 ROS 镜像）与 sudo 权限。
set -e

SRC="${CHEZMOI_SOURCE_DIR:?CHEZMOI_SOURCE_DIR 未设置，请通过 chezmoi apply 运行}"
APT_SRC="$SRC/manifests/apt-sources"

if ! command -v apt-get >/dev/null 2>&1; then
    echo "非 Debian/Ubuntu 系统，跳过 apt 安装。"
    exit 0
fi

echo "==> 写入第三方 APT 源与公钥"
sudo install -m 0644 \
    "$APT_SRC/vscode.sources" \
    "$APT_SRC/cursor.sources" \
    "$APT_SRC/christian-boxdoerfer-ubuntu-fsearch-stable-noble.sources" \
    "$APT_SRC/matinlotfali-ubuntu-kde-rounded-corners-noble.sources" \
    "$APT_SRC/ros-fish.list" \
    /etc/apt/sources.list.d/
sudo install -m 0644 "$APT_SRC/keys/microsoft.gpg" "$APT_SRC/keys/anysphere.gpg" /usr/share/keyrings/
sudo install -m 0644 "$APT_SRC/keys/ros.gpg" /etc/apt/trusted.gpg.d/

export DEBIAN_FRONTEND=noninteractive
echo "==> apt-get update"
sudo -E apt-get update

PKGS=$(grep -v '^#' "$SRC/manifests/apt-install.txt" | grep -v '^$' | tr '\n' ' ')
echo "==> 安装 apt 软件清单（$(printf '%s\n' $PKGS | wc -l) 个包）"
if ! sudo -E apt-get install -y $PKGS; then
    echo "批量安装失败，回退为逐个安装，失败项记录到 /tmp/tuned-ubuntu-apt-failed.txt"
    : > /tmp/tuned-ubuntu-apt-failed.txt
    for p in $PKGS; do
        sudo -E apt-get install -y "$p" || echo "$p" >> /tmp/tuned-ubuntu-apt-failed.txt
    done
    echo "可在新机器上手动处理：/tmp/tuned-ubuntu-apt-failed.txt"
fi
echo "==> apt 安装完成"
