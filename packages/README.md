# 软件清单

本目录存放我 Arch Linux 上的软件清单，用于重装系统时复现。
清单来源：`pacman -Qe`（显式安装）与 `pacman -Qm`（外部/AUR 包）。

- `pacman.txt` — 显式安装包（官方仓库 + 显式装的），含补装项 `playerctl`
- `aur.txt` — archlinuxcn / AUR 外部包
- `install.sh` — 一键恢复脚本（需先启用 archlinuxcn 仓库 + 装 paru）

---

## 分类清单（给人看）

### 系统核心 / 引导 / 内核
base · base-devel · linux-zen · linux-zen-headers · linux-firmware · amd-ucode · grub · efibootmgr · os-prober · openssh · man-db

### 显卡（NVIDIA Optimus 笔记本）
nvidia-open-dkms · nvidia-utils · lib32-nvidia-utils · libva-nvidia-driver · nvidia-prime · mesa-utils

### Hyprland / Wayland 显示栈
hyprland · hyprpolkitagent · hyprpicker · quickshell · xdg-desktop-portal-hyprland · xdg-desktop-portal-termfilechooser · grim · slurp · wl-clipboard · wl-clip-persist · cliphist · brightnessctl

### 音频 / 网络 / 后台服务
pipewire · pipewire-pulse · wireplumber · bluez · bluez-utils · networkmanager · gnome-keyring

### 终端 / Shell / 生产力
fish · kitty · starship · tmux · yazi · btop · nvtop · fzf · fd · jq · neovim · git

### 输入法
fcitx5 · fcitx5-chinese-addons · fcitx5-configtool · fcitx5-gtk · fcitx5-qt · fcitx5-pinyin-zhwiki

### GUI 应用
mpv · mpv-modernz · pigma · obs-studio · inkscape · satty · google-chrome · visual-studio-code-bin · linuxqq · clash-verge-rev-bin

### Qt / 主题工具
kvantum · kvantum-qt5 · qt5ct · qt6ct · qt5-wayland · qt6-wayland · qt6-shadertools · nwg-look

### 图片 / 媒体处理
imagemagick · resvg · awww

### 字体 / 图标
noto-fonts · noto-fonts-cjk · noto-fonts-emoji · ttf-maplemono-nf-cn-unhinted · papirus-icon-theme

### 开发 / 工具链
clang · nodejs · npm · shfmt · paru · trash-cli · 7zip

### 包管理辅助
archlinuxcn-keyring · rebuild-detector

### 补装 / 可选（配置文件引用但当前未装）
- **playerctl**（官方仓库）— `hyprland.lua` 媒体键（播放/暂停/下一首）需要，**必装**
- **hyprshutdown**（AUR，可选）— `hyprland.lua` SUPER+Q 引用，但有 fallback，装不装都能退出

---

## 依赖说明
`pacman.txt`/`aur.txt` 只列**显式安装**的包；`sensors`(lm_sensors)、`ip`(iproute2)、
`killall`(psmisc)、`notify-send`(libnotify)、`xdg-desktop-portal` 等都是**间接依赖**，
重装时会由相关包自动带上（quickshell 的 cpu/network 脚本、portal 等需要它们）。

## 重装流程（简）
1. 装好 base 系统 + 启用 `archlinuxcn` 仓库 + `archlinuxcn-keyring`
2. `sudo pacman -S paru`
3. 本目录运行 `bash install.sh`
4. 把 `config-v3/` 拷到 `~/.config/`，`home/` 内容拷到 `~`
5. 手动放置主题/光标：`~/.local/share/themes/Orchis-Grey-Dark`、`~/.local/share/icons/GoogleDot-Blue`
