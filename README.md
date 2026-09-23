# tuned-ubuntu

我在 Ubuntu 24.04（KDE Plasma 5.27 / X11）上调教好的桌面与终端环境，用
[chezmoi](https://www.chezmoi.io) 管理，可在全新系统上快速部署。

覆盖内容：KDE 外观（Catppuccin Mocha Mauve + Kvantum + KZones 平铺 + ShapeCorners 圆角 +
Bibata 光标）、Konsole、fcitx5 输入法、GTK/字体渲染、zsh + powerlevel10k、软件清单、
系统级微调脚本。仓库公开，不含任何密钥。

> **与旧仓库的关系**：[hair-0/ohmyzsh-config](https://github.com/hair-0/ohmyzsh-config)
> 是只含 zsh / powerlevel10k 的精简仓库，本仓库是完整桌面版。
> 两个仓库的 `dot_zshrc.tmpl` / `dot_p10k.zsh` **内容完全一致**，且为跨系统自适应：
> 自动探测 conda 目录（`~/miniforge3` / `~/miniconda3`）、自动适配 ROS 发行版
> （humble/jazzy…）、WSL 下自动启用 `e.` 别名、nvm 通过 `~/.zshrc.local` 按机器启用。
> 差异只在仓库范围（shell-only vs 全桌面）；改动这两个文件时请**两边同步提交**。

---

## 目录

1. [仓库结构](#仓库结构)
2. [部署流程总览](#部署流程总览)
3. [前置条件与网络](#前置条件与网络)
4. [一键部署](#一键部署)
5. [自动部署的每一步（含等价手动命令）](#自动部署的每一步含等价手动命令)
6. [部署后验证](#部署后验证)
7. [部署后手动收尾](#部署后手动收尾)
8. [日常维护](#日常维护)
9. [排错](#排错)
10. [安全说明与已知限制](#安全说明与已知限制)

---

## 仓库结构

```
tuned-ubuntu/                          chezmoi 源目录（git 仓库，克隆在 ~/.local/share/chezmoi）
│
├── README.md                          本文档（不落盘）
├── .chezmoiignore                     排除清单：密钥 / 应用数据 / 机器相关 / 缓存
├── .gitignore                         历史、.ssh、env 等
│
├── .chezmoiscripts/                   ★ 部署脚本，按文件名 ASCII 顺序执行
│   ├── run_once_00-apt.sh                 ① 写第三方 apt 源 + 装 441 个包      [sudo][联网]
│   ├── run_once_01-snap-flatpak.sh        ② snap ×10 + flatpak ×1              [sudo][联网]
│   ├── run_once_02-assets.sh              ③ Bibata 光标 + 2 套 Nerd Font       [联网]
│   ├── run_once_03-neovim.sh              ④ 克隆 neovim 配置 + 恢复插件
│   ├── run_once_install-nerd-font.sh      ⑤ MesloLGS NF（p10k 图标字体）      [联网]
│   ├── run_once_install-oh-my-zsh.sh      ⑥ oh-my-zsh + 插件 + powerlevel10k   [联网]
│   └── run_onchange_system-tweaks.sh      ⑦ /etc 系统微调                      [sudo]
│
├── manifests/                         软件清单（不落盘，仅被脚本读取）
│   ├── apt-install.txt                    441 个 apt 包
│   ├── apt-sources/                       第三方源 + 公钥
│   │   ├── vscode.sources                     VSCode     （key: keys/microsoft.gpg）
│   │   ├── cursor.sources                     Cursor     （key: keys/anysphere.gpg）
│   │   ├── christian-boxdoerfer-...sources    FSearch    （内联公钥）
│   │   ├── matinlotfali-...-noble.sources     ShapeCorners PPA（内联公钥）
│   │   ├── ros-fish.list                      ROS 2（清华镜像，key: keys/ros.gpg）
│   │   └── keys/                              公钥（公开信息，可入库）
│   ├── snaps.txt                          blender/cmake/emacs/nvim(--classic) + vlc 等
│   └── flatpaks.txt                       flathub org.fcitx.Fcitx5
│
└── dotfiles 到 $HOME 的映射
    ├── dot_zshrc.tmpl             →  ~/.zshrc                 （conda/ROS/WSL 环境自适应）
    ├── dot_p10k.zsh               →  ~/.p10k.zsh
    ├── dot_gitconfig              →  ~/.gitconfig
    ├── dot_pam_environment        →  ~/.pam_environment       （GTK/QT/XMODIFIERS 输入法变量）
    ├── dot_xinputrc               →  ~/.xinputrc              （im-config 选 fcitx5）
    ├── dot_profile / dot_zprofile →  ~/.profile / ~/.zprofile
    ├── dot_gtkrc-2.0              →  ~/.gtkrc-2.0
    ├── dot_fonts.conf             →  ~/.fonts.conf
    ├── dot_jetbrains.vmoptions.sh →  ~/.jetbrains.vmoptions.sh
    ├── private_dot_config/        →  ~/.config/
    │   ├── KDE：kdeglobals / konsolerc / kwinrc / kwinrulesrc / kcminputrc /
    │   │        kglobalshortcutsrc / kxkbrc / plasmarc / plasmashellrc /
    │   │        breezerc / plasma-localerc / kdedefaults/ / khotkeysrc /
    │   │        krunnerrc / kscreenlockerrc / plasma-org.kde.plasma.desktop-appletsrc
    │   ├── fcitx5/（config、profile、各输入法 conf）
    │   ├── gtk-3.0/ gtk-4.0/（Catppuccin colors.css/gtk.css + settings.ini + 窗口按钮 svg）
    │   ├── Kvantum/（catppuccin-mocha-mauve 主题）
    │   ├── xsettingsd/、autostart/、mimeapps.list、gtkrc
    │   └── dolphinrc / katerc / kateschemarc / katevirc
    └── private_dot_local/share/   →  ~/.local/share/
        ├── konsole/（Dev.profile + catppuccin-mocha.colorscheme）
        ├── color-schemes/CatppuccinMochaMauve.colors
        ├── fcitx5/themes/（plasma、default-dark）
        └── kwin/scripts/kzones/（窗口平铺脚本）
```

---

## 部署流程总览

```
 全新 Ubuntu 24.04
        │
        ▼
 ┌──────────────────────────────────────────────────────────────┐
 │ [0] 安装 chezmoi（~/.local/bin/chezmoi）                     │
 └──────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌──────────────────────────────────────────────────────────────┐
 │ [1] chezmoi init --apply hair-0/tuned-ubuntu                 │
 │                                                              │
 │   文件先落盘：KDE / Konsole / fcitx5 / GTK / Kvantum / zsh…  │
 │        │                                                     │
 │        ├─ ① run_once_00-apt.sh        写源 + apt update + 441 包  [sudo] │
 │        ├─ ② run_once_01-snap-flatpak  snap 10 个 + flatpak 1 个   [sudo] │
 │        ├─ ③ run_once_02-assets.sh     Bibata + FiraCode/JetBrainsMono NF │
 │        ├─ ④ run_once_03-neovim.sh     clone neovim-config + Lazy restore │
 │        ├─ ⑤ run_once_install-nerd-font.sh   MesloLGS NF      │
 │        ├─ ⑥ run_once_install-oh-my-zsh.sh   omz + 插件 + p10k │
 │        └─ ⑦ run_onchange_system-tweaks.sh   /etc 微调        [sudo] │
 └──────────────────────────────────────────────────────────────┘
        │
        ▼
 [2] 注销重新登录（fcitx5 环境变量、KDE 主题/面板生效；建议直接重启）
        │
        ▼
 [3] 手动收尾：Wi-Fi / 显示器布局 / KWin 窗口规则 / 第三方 App / SSH 密钥
```

脚本命名规则（chezmoi 约定）：

| 前缀 | 何时执行 | 本仓库用途 |
|---|---|---|
| `run_once_` | 每台机器只执行一次；**内容变化后也会再执行**（按内容 SHA256 记录） | 装包、下载资产、克隆仓库 |
| `run_onchange_` | 首次 + **内容变化时**执行 | 系统级微调（改动脚本即重跑） |

脚本执行顺序 = **目标路径的 ASCII 顺序**，因此本仓库用 `00`、`01`… 前缀强行定序；
`.chezmoiscripts/` 是 chezmoi 特殊目录，脚本只执行、不会在 `$HOME` 里创建目录。

---

## 前置条件与网络

- **系统**：Ubuntu 24.04（本配置按 Kubuntu 24.04 + Plasma 5.27 调教）
- **权限**：能使用 `sudo`；部署过程中会多次要求输入密码
- **磁盘**：约 4–6 GB（apt 包 + snap + flatpak + 字体）
- **网络**：能访问 GitHub / Launchpad / 微软源 / 清华 ROS 镜像。GitHub 不通时先配代理：

```sh
# Clash Verge 的混合端口示例（按实际端口修改）
export https_proxy=http://127.0.0.1:7897
export http_proxy=http://127.0.0.1:7897
export all_proxy=socks5://127.0.0.1:7897

# 验证
curl -I https://github.com
```

Git 克隆默认走 HTTPS，会继承上面的 `https_proxy`；如果代理只对浏览器生效，
也可以改走 SSH（免代理，需要 GitHub 密钥）：

```sh
ssh -T git@github.com        # 出现 "Hi <user>!" 即成功
chezmoi init --apply --ssh hair-0/tuned-ubuntu
```

部署前建议先做一次模拟（不改任何文件）：

```sh
chezmoi init --apply --dry-run --verbose hair-0/tuned-ubuntu   # 预览
```

---

## 一键部署

**方式 A：一条命令（自动安装 chezmoi 到 `~/.local/bin`）**

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply hair-0/tuned-ubuntu
```

**方式 B：已安装 chezmoi**

```sh
chezmoi init --apply hair-0/tuned-ubuntu
```

执行前可以先 `sudo -v` 预先缓存 sudo 凭据，避免中途反复输密码。

如果 `get.chezmoi.io` 不通：从 [chezmoi Releases](https://github.com/twpayne/chezmoi/releases/latest)
下载 `chezmoi_*_linux_amd64.tar.gz`，解压 `chezmoi` 到 `~/.local/bin`，再执行方式 B。

部署完成后：

```sh
exec zsh          # 或注销重登
sudo reboot       # 推荐：让主题、fcitx5、KWin 规则、面板完全生效
```

---

## 自动部署的每一步（含等价手动命令）

> 下面的手动命令均假设已 `chezmoi cd`（即当前目录为 `~/.local/share/chezmoi`）。
> 不想用 chezmoi 时，按顺序手动执行即可达到同样效果。

### ① run_once_00-apt.sh — 第三方 apt 源 + 441 个包（sudo）

脚本做的事：

```sh
# 1) 写入第三方源与公钥
sudo install -m 0644 manifests/apt-sources/*.sources /etc/apt/sources.list.d/
sudo install -m 0644 manifests/apt-sources/ros-fish.list /etc/apt/sources.list.d/
sudo install -m 0644 manifests/apt-sources/keys/microsoft.gpg \
                    manifests/apt-sources/keys/anysphere.gpg /usr/share/keyrings/
sudo install -m 0644 manifests/apt-sources/keys/ros.gpg /etc/apt/trusted.gpg.d/

# 2) 更新索引
sudo apt-get update

# 3) 安装清单内所有包
sudo apt-get install -y $(grep -v '^#' manifests/apt-install.txt | tr '\n' ' ')
```

- 清单含 KDE 全家桶、fcitx5、开发工具（git/vim/tmux/ripgrep/pandoc/gdb…）、ROS Jazzy、
  VSCode（`code`）、Cursor、FSearch、ShapeCorners（`kwin-effect-roundcorners`）、
  Qt Kvantum 风格等。
- 批量安装失败时脚本会自动退化为逐个安装，失败清单写入 `/tmp/tuned-ubuntu-apt-failed.txt`。
- 故意**未包含**：内核（`linux-image-*`）、grub/shim、Intel 驱动、`ttf-mscorefonts-installer`（需 EULA）。

### ② run_once_01-snap-flatpak.sh — snap / flatpak（sudo）

```sh
# snap：4 个 classic + 6 个普通
sudo snap install blender cmake emacs nvim --classic
sudo snap install ffmpeg-2404 firefox freecad gazebo gimp vlc

# flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub org.fcitx.Fcitx5
```

### ③ run_once_02-assets.sh — 光标与字体（联网）

```sh
mkdir -p ~/.local/share/icons ~/.local/share/fonts

# Bibata 光标 v2.0.7（27 MB，解压出 ~/.local/share/icons/Bibata-Modern-Classic）
curl -fL -o /tmp/bibata.tar.xz \
  https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz
tar -xf /tmp/bibata.tar.xz -C ~/.local/share/icons

# Nerd Fonts（图标字体）
curl -fL -o /tmp/FiraCode.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
mkdir -p ~/.local/share/fonts/FiraCodeNerdFont
unzip -o /tmp/FiraCode.zip -d ~/.local/share/fonts/FiraCodeNerdFont

curl -fL -o /tmp/JetBrainsMono.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
mkdir -p ~/.local/share/fonts/JetBrainsMonoNerdFont
unzip -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMonoNerdFont

fc-cache -f ~/.local/share/fonts
```

> 本机 985 MB 的字体目录**不入库**；MesloLGS NF 由脚本 ⑤ 单独安装，中文/Noto 字体由 apt 清单提供。

### ④ run_once_03-neovim.sh — 独立仓库的 neovim 配置

```sh
git clone --depth 1 https://github.com/hair-0/neovim-config.git ~/.config/nvim
nvim --headless "+Lazy! restore" +qa     # 按 lazy-lock.json 恢复插件
```

### ⑤ run_once_install-nerd-font.sh — MesloLGS NF（p10k 图标）

```sh
FONT_DIR=~/.local/share/fonts; mkdir -p "$FONT_DIR"
for n in "MesloLGS NF Regular" "MesloLGS NF Bold" "MesloLGS NF Italic" "MesloLGS NF Bold Italic"; do
  curl -fSL -o "$FONT_DIR/$n.ttf" \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/$(printf '%s' "$n" | sed 's/ /%20/g').ttf"
done
fc-cache -f "$FONT_DIR"
```

### ⑥ run_once_install-oh-my-zsh.sh — oh-my-zsh + 插件 + 主题

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  "" --unattended --keep-zshrc
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
  ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/zsh-users/zsh-completions \
  ~/.oh-my-zsh/custom/plugins/zsh-completions
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting \
  ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone --depth 1 https://github.com/romkatv/powerlevel10k \
  ~/.oh-my-zsh/custom/themes/powerlevel10k
```

### ⑦ run_onchange_system-tweaks.sh — 系统级微调（sudo）

```sh
# vim 显示行号
echo 'set number' | sudo tee -a /etc/vim/vimrc

# ALSA：禁用 dmic 探测（部分机型内置麦克风需要；重载声卡或重启后生效）
echo 'options snd-hda-intel dmic_detect=0' | sudo tee -a /etc/modprobe.d/alsa-base.conf

# 生成 locale
sudo locale-gen en_US.UTF-8 zh_CN.UTF-8
```

> 其余 `/etc` 文件的改动经 `dpkg --verify` 审计后确认只是包管理/机器相关差异，未纳入。
> `/etc` 中还有 `kdesu-sudoers` 等 root 私有文件，如需迁移请手动处理。

---

## 部署后验证

在**新终端**（或重启后）逐项核对：

| 项目 | 命令 | 期望值 |
|---|---|---|
| 全局主题 | `kreadconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage` | `org.kde.breezedark.desktop` |
| 图标主题 | `kreadconfig5 --file kdeglobals --group Icons --key Theme` | `Yaru-blue` |
| 颜色方案 | `kreadconfig5 --file kdeglobals --group General --key ColorScheme` | `CatppuccinMochaMauve` |
| 应用风格 | `kreadconfig5 --file kdeglobals --group KDE --key widgetStyle` | `kvantum` |
| 窗口装饰 | `kreadconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme` | `Breeze` |
| KZones | `kreadconfig5 --file kwinrc --group Plugins --key kzonesEnabled` | `true` |
| ShapeCorners | `kreadconfig5 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled` | `true` |
| 光标 | `kreadconfig5 --file kcminputrc --group Mouse --key cursorTheme` | `Bibata-Modern-Classic` |
| Konsole 方案 | `kreadconfig5 --file konsolerc --group UiSettings --key ColorScheme` | `catppuccin-mocha` |
| Konsole 描述文件 | `kreadconfig5 --file konsolerc --group "Desktop Entry" --key DefaultProfile` | `Dev.profile` |
| Kvantum 主题 | `grep theme= ~/.config/Kvantum/kvantum.kvconfig` | `theme=catppuccin-mocha-mauve` |
| 字体 | `fc-list \| grep -c "MesloLGS NF"` | ≥ 4 |
| | `fc-list \| grep -ci "FiraCode Nerd Font"` | ≥ 4 |
| | `fc-list \| grep -ci "JetBrainsMono Nerd"` | ≥ 4 |
| KZones 已加载 | `kpackagetool5 --type=KWin/Script --list` | 输出含 `kzones` |
| 输入法 | `fcitx5-diagnose \| head -40` | 无红色报错 |
| | `echo $GTK_IM_MODULE $QT_IM_MODULE $XMODIFIERS` | `fcitx fcitx @im=fcitx` |
| apt 包数量 | `apt-mark showmanual \| wc -l` | 与部署前相近（约 480） |
| snap | `snap list` | 含 blender/emacs/nvim/vlc 等 |
| flatpak | `flatpak list --app` | 含 `org.fcitx.Fcitx5` |
| zsh | `exec zsh` 后 | 出现 p10k 提示符（带图标） |
| 面板/托盘 | 注销重登后 | 托盘图标常驻、面板布局与旧机一致 |

输入法环境变量自检与修复：

```sh
im-config -n fcitx5          # 重新指定输入法框架
exec zsh                     # 或注销重登
```

---

## 部署后手动收尾

### 1. 网络（Wi-Fi / 有线）

凭据不入库，需重新连接：

```sh
nmcli device wifi list
nmcli device wifi connect "SSID" password "PASSPHRASE"
nmcli connection show
```

### 2. 显示器布局

旧机是 eDP-1（2880x1920, 缩放 1.5）+ DP-3（2560x1600），新机通常不同：

```sh
kscreen-doctor -o            # 查看输出、模式、缩放
systemsettings5 kcm_kscreen  # GUI 调整分辨率/缩放/排列
```

### 3. KWin 窗口规则（含旧机坐标）

`kwinrulesrc` 里有一条按旧显示器写的 Konsole 规则（`1858x1464 @3035,278`）：

```sh
# 查看规则数量
kreadconfig5 --file kwinrulesrc --group General --key count

# 方式一：GUI 删除/修改（系统设置 → 窗口管理 → 窗口规则）
# 方式二：不再需要规则时整体删除
rm -f ~/.config/kwinrulesrc

# 规则改动后重启 KWin 生效
kwin_x11 --replace &
```

### 4. 面板 / 托盘微调

`appletsrc` 已还原，若屏幕数量不同导致面板错位：

```sh
kquitapp5 plasmashell; sleep 2; setsid plasmashell >/dev/null 2>&1 & disown
# 仍不对时：系统设置 → 开机与关机 → 桌面会话 → 另存为默认会话
```

### 5. 第三方应用（没有公开 apt 源，需手动装）

- 有 apt 源的已自动安装：**VSCode、Cursor、FSearch**
- 建议用 flatpak（先 `flatpak search <关键词>`）：
  ```sh
  flatpak install flathub md.obsidian.Obsidian
  flatpak install flathub org.onlyoffice.desktopeditors
  ```
- 其余从官网/Release 下载 deb：Chrome、Edge、WPS、微信、飞书、百度网盘、
  Clash Verge（[clash-verge-rev/clash-verge-rev](https://github.com/clash-verge-rev/clash-verge-rev) 的 `.deb`）、
  ToDesk/tdappdesktop、欧路词典、MarkText、Kazumi、GitHub Desktop、Remmina、XDM、qBittorrent。

### 6. 开发环境

```sh
# miniforge3（.zshrc 会自动探测 ~/miniforge3 / ~/miniconda3，装到任一目录即可）
curl -fLO https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p ~/miniforge3
# 注意：不要运行 `conda init zsh`——会向 ~/.zshrc 追加重复块，与 chezmoi 管理冲突

# nvm：默认不加载（与 p10k 的 nvm 段无关）。装好后在 ~/.zshrc.local 中加入：
#   export NVM_DIR="$HOME/.nvm"
#   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
#   [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

# fzf（.zshrc 会 source ~/.fzf.zsh）
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all

# ROS 2 已随 apt 清单安装（/opt/ros/jazzy），初始化 rosdep：
sudo rosdep init && rosdep update

# kimi-code：放回 ~/.kimi-code/bin（.zshrc 已加入 PATH）
```

### 7. SSH 密钥与 GitHub

```sh
ls ~/.ssh                    # 公钥私钥均不入库，从密码管理器恢复
ssh-keygen -t ed25519 -f ~/.ssh/github_personal -C "your@email"
ssh -T git@github.com        # 验证
```

`~/.ssh/config`（tinker1/qxyserver 等主机别名）也需要手动恢复。

---

## 日常维护

在**装载机器**上修改配置后，同步回仓库：

```sh
chezmoi add ~/.config/kdeglobals     # 把新改动纳入管理
chezmoi re-add                       # 批量同步已管理文件的改动（模板文件除外）
chezmoi edit ~/.zshrc                # 直接编辑源文件（模板可正确定位）
chezmoi status                       # 查看哪些文件/脚本有差异
chezmoi diff                         # 预览会写入 $HOME 的内容
chezmoi cd                           # 进入源目录
git add -A && git commit -m "update: ..." && git push
```

在其他机器上应用最新配置：

```sh
chezmoi update                       # = git pull + apply
chezmoi apply --dry-run --verbose    # 应用前预演
```

强制重跑脚本（改脚本文件本身即可触发；也可清状态）：

```sh
chezmoi state delete-bucket --bucket=scriptState   # 清 run_once 记录
chezmoi state delete-bucket --bucket=entryState    # 清 run_onchange 记录
chezmoi apply
```

跳过脚本只应用文件：

```sh
chezmoi apply --exclude=scripts
```

---

## 排错

```sh
chezmoi doctor                       # 环境自检（版本/配置/git 等）
chezmoi data                         # 查看模板可用变量（os/arch/homeDir…）
chezmoi unmanaged | head             # 查看未被管理的文件
chezmoi managed | tail               # 查看已管理的文件

# GitHub 不通
curl -I https://github.com           # 失败则配置代理（见前文）或改用 SSH
chezmoi init --apply --ssh hair-0/tuned-ubuntu

# apt 安装失败
cat /tmp/tuned-ubuntu-apt-failed.txt

# fcitx5 不生效
fcitx5-diagnose | less
im-config -n fcitx5 && 注销重登
```

`chezmoi apply` 时如果目标文件被手动改过，会提示冲突，用
`chezmoi merge <文件>` 或 `chezmoi add <文件>` 解决。

---

## 安全说明与已知限制

**不入库**（见 `.chezmoiignore`）：`.ssh/`、`.gnupg/`、`.openai_config`、`.claude*`、
kwallet、goa/remmina/plasma-nm 等凭据、浏览器与聊天应用数据（Chrome/Edge/Code/Cursor/
LarkShell/TDAppDesktop/obsidian…，`~/.config` 约 5 GB 的大头）、`kscreen/` 显示器布局、
shell 历史、缓存、字体目录（985 MB）、`~/.config/nvim`（由独立仓库管理）。

**已知限制**：

- 配置针对 Ubuntu 24.04 + Plasma 5.27；升级到 Plasma 6 后部分 KDE 配置需要适配。
- `appletsrc` / `kwinrulesrc` 与旧机双屏布局（eDP-1 + DP-3）绑定，新机需按上文微调。
- 公开仓库永远不要提交私钥/密码；如需备份敏感配置，请用 chezmoi 的
  [age/gpg 加密](https://www.chezmoi.io/user-guide/encryption/)功能。
- 关联仓库：
  - [hair-0/neovim-config](https://github.com/hair-0/neovim-config) — neovim 配置（独立 git 仓库）
  - [hair-0/ohmyzsh-config](https://github.com/hair-0/ohmyzsh-config) — 只含同一份跨系统自适应的 zsh/p10k（shell-only 精简仓库）
