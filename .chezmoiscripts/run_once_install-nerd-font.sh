#!/bin/sh
# run_once_install-nerd-font.sh
# 安装 powerlevel10k 官方推荐的 MesloLGS NF 到 ~/.local/share/fonts。
# 由 chezmoi apply 在每台新机器上执行一次（幂等：已安装则跳过）。
# 下载源：https://github.com/romkatv/powerlevel10k-media
set -e

FONT_DIR="${HOME}/.local/share/fonts"
BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"

mkdir -p "$FONT_DIR"

if command -v fc-list >/dev/null 2>&1 && fc-list 2>/dev/null | grep -qi "MesloLGS NF"; then
    echo "MesloLGS NF already installed; skip."
    exit 0
fi

for name in "MesloLGS NF Regular" "MesloLGS NF Bold" "MesloLGS NF Italic" "MesloLGS NF Bold Italic"; do
    dest="$FONT_DIR/${name}.ttf"
    [ -f "$dest" ] && continue
    enc=$(printf '%s' "$name" | sed 's/ /%20/g')
    echo "Downloading ${name}.ttf ..."
    if ! curl -fSL --retry 5 --retry-delay 3 --retry-all-errors -o "$dest" "$BASE_URL/${enc}.ttf"; then
        echo "ERROR: failed to download ${name}.ttf" >&2
        exit 1
    fi
done

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -fv "$FONT_DIR" >/dev/null 2>&1 || true
fi
echo "MesloLGS NF installed to ${FONT_DIR}"
