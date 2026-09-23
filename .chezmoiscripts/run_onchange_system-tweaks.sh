#!/bin/sh
# run_onchange_system-tweaks.sh — 系统级调整（需要 sudo）。
# v1 (2026-09-23)：vim 行号 / snd-hda-intel dmic_detect / en_US+zh_CN locale。
# chezmoi 会在本文件内容变化时自动重跑；命令均为幂等操作。
set -e

# 1. vim：显示行号
if ! grep -qx 'set number' /etc/vim/vimrc 2>/dev/null; then
    echo 'set number' | sudo tee -a /etc/vim/vimrc >/dev/null
    echo "已写入: /etc/vim/vimrc (set number)"
fi

# 2. ALSA：禁用 dmic 探测（部分笔记本内置麦克风需要；需重载驱动或重启生效）
if ! grep -q 'snd-hda-intel dmic_detect=0' /etc/modprobe.d/alsa-base.conf 2>/dev/null; then
    echo 'options snd-hda-intel dmic_detect=0' | sudo tee -a /etc/modprobe.d/alsa-base.conf >/dev/null
    echo "已写入: /etc/modprobe.d/alsa-base.conf (dmic_detect=0)"
fi

# 3. locale：生成 en_US 与 zh_CN
if command -v locale-gen >/dev/null 2>&1; then
    sudo locale-gen en_US.UTF-8 zh_CN.UTF-8 || true
fi

echo "==> 系统级调整完成"
