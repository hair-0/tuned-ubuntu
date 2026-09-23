# tuned-ubuntu

我在 Ubuntu 24.04（KDE Plasma 5.27 / X11）上调教好的桌面与终端环境，用
[chezmoi](https://www.chezmoi.io) 管理，可在全新系统上快速部署。

包含：KDE 外观（Catppuccin + Kvantum + 圆角/KZones + Bibata 光标）、Konsole、
fcitx5 输入法、GTK/字体渲染、zsh + powerlevel10k、软件清单与系统级微调脚本。

## 一键部署

全新 Ubuntu 24.04 上执行（需联网，网络受限时先配置代理）：

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply hair-0/tuned-ubuntu
```

已装 chezmoi 则直接：

```sh
chezmoi init --apply hair-0/tuned-ubuntu
```

> 若 `get.chezmoi.io` 不通，从 [chezmoi Releases](https://github.com/twpayne/chezmoi/releases/latest)
> 下载 `linux_amd64` 解压到 `~/.local/bin` 再执行上面第二条。
> 部署过程会多次要求 sudo 密码（写 apt 源、装包、系统微调）。
> 网络受限时先 `export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897`（按实际代理端口改）。

## 部署流程（自动）

| 顺序 | 脚本 | 内容 |
|---|---|---|
| 1 | `run_once_00-apt.sh` | 写入第三方 apt 源与公钥，安装 `manifests/apt-install.txt`（441 包） |
| 2 | `run_once_01-snap-flatpak.sh` | 按清单装 snap（blender/emacs/nvim/vlc…）与 flatpak（fcitx5） |
| 3 | `run_once_02-assets.sh` | 下载 Bibata 光标、FiraCode / JetBrainsMono Nerd Font |
| 4 | `run_once_03-neovim.sh` | 克隆 [neovim-config](https://github.com/hair-0/neovim-config) 到 `~/.config/nvim` 并恢复插件 |
| — | `run_once_install-*.sh` | oh-my-zsh、powerlevel10k、zsh 插件、MesloLGS NF |
| — | `run_onchange_system-tweaks.sh` | sudo 应用 `/etc/vim/vimrc`、alsa `dmic_detect=0`、locale |

主题类小文件（Catppuccin 配色、Konsole 方案、Kvantum、fcitx5 主题、KZones、GTK CSS）
直接收录在仓库中，由 `chezmoi apply` 自动落盘。

## 部署后需要手动做的事

- **网络**：Wi-Fi/有线连接需重新配置（凭据不入库）；
- **显示器**：分辨率/缩放/排列按新机器重设（`kscreen` 已排除）；
- **KWin 窗口规则**：`kwinrulesrc` 中有按旧显示器坐标写的规则（如 Konsole 1858x1464 @3035,278），
  新机器需在 系统设置 → 窗口管理 → 窗口规则 中调整或删除；
- **Plasma 面板**：`plasma-org.kde.plasma.desktop-appletsrc` 已入库，一般可还原；
  若新机器屏幕数量/编号不同，托盘的屏幕特定容器可能需要微调；
- **第三方应用**（无公开 apt 源，未包含在脚本中，需自行安装）：
  Chrome、Edge、Obsidian、OnlyOffice、WPS、微信、飞书、百度网盘、Clash Verge、
  ToDesk、欧路词典、MarkText、Kazumi、GitHub Desktop、Todesk 等；
- **密钥与账号**：SSH/GPG 私钥、GitHub token、各应用登录态一律不备份，请从密码管理器恢复；
- **开发环境**：miniforge/conda（`~/.zshrc` 已按 `~/miniforge3` 渲染）、nvm（默认禁用）、
  ROS Jazzy（apt 清单内含，`/opt/ros/jazzy`）、kimi-code 需自行放置。

## 仓库结构

```
.chezmoiignore                  # 排除清单：密钥/应用数据/机器相关/缓存大文件
.chezmoiscripts/                # 安装脚本（chezmoi 约定命名，按序执行）
manifests/
├── apt-install.txt             # apt 软件清单
├── apt-sources/                # 第三方 apt 源定义 + 公钥
├── snaps.txt / flatpaks.txt    # snap / flatpak 清单
dot_zshrc.tmpl / dot_p10k.zsh   # shell
private_dot_config/...          # KDE、Konsole、fcitx5、GTK、Kvantum 等配置
private_dot_local/share/...     # 主题、配色方案、KZones
```

## 日常维护

```sh
chezmoi add ~/.config/kdeglobals      # 把新改动纳入管理
chezmoi diff                          # 预览会应用什么
chezmoi cd && git add -A && git commit -m "..." && git push
chezmoi update                        # 其他机器拉取最新并应用
```

## 安全说明

仓库公开，**任何私钥、token、Wi-Fi 密码、浏览器数据都不会入库**（见 `.chezmoiignore`）。
`.config/nvim` 是独立 git 仓库（neovim-config），本仓库只负责克隆它。

## 已知限制

- 配置针对 Ubuntu 24.04 + Plasma 5.27 调教；升级 Plasma 6 后 KDE 配置需另行适配。
- `kwinrc` 启用了 KZones（脚本已入库）与 ShapeCorners（apt 包 `kwin-effect-roundcorners`）。
- 系统级改动仅保留明确的自定义项；`/etc` 残留的其他修改以 `dpkg --verify` 审计为准。
