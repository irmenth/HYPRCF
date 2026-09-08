#!/usr/bin/env bash
# ============================================================
#  HYPRCF 软件清单恢复脚本
#  用法: 以【普通用户】运行  bash install.sh
#  （paru 安装官方/archlinuxcn 包会自动 sudo；AUR 构建以当前用户执行）
#  前置: 全新 Arch 需先装好 base/base-devel/git，并启用 archlinuxcn 仓库
# ============================================================
set -euo pipefail

cd "$(dirname "$0")"

echo "==> [1/4] 检查 paru (AUR 帮手)..."
if ! command -v paru >/dev/null 2>&1; then
    echo "!! 未找到 paru。请先安装: sudo pacman -S paru"
    exit 1
fi

echo "==> [2/4] 检查 archlinuxcn 仓库是否已启用..."
if ! grep -q '^\[archlinuxcn\]' /etc/pacman.conf; then
    echo "!! /etc/pacman.conf 未启用 archlinuxcn 仓库。"
    echo "   请先在 pacman.conf 追加："
    echo "     [archlinuxcn]"
    echo "     Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch"
    echo "   然后: sudo pacman -Sy && sudo pacman -S archlinuxcn-keyring"
    echo "   （否则 chrome/qq/vscode/clash/mpv-modernz 装不上）"
    echo "   教程: https://wiki.archlinux.org/title/Arch_User_Repository"
    exit 1
fi

echo "==> [3/4] 解析包名（取每行首列，跳过以 # 开头的注释行）..."
pkgs=$(grep -v '^[[:space:]]*#' pacman.txt aur.txt | awk '{print $1}' | tr '\n' ' ')
echo "    共 $(echo $pkgs | wc -w) 个包"

echo "==> [4/4] 安装（--needed 会跳过已装的）..."
paru -S --needed --noconfirm $pkgs

echo ""
echo "==> 完成。请确认以下补装项："
echo "    - playerctl   : sudo pacman -S playerctl"
echo "      (hyprland.lua 媒体键控制需要，当前清单已标注但未安装)"
echo "    - hyprshutdown: (可选) paru -S hyprshutdown"
echo "      (hyprland.lua 的 SUPER+Q 有 fallback，装不装都能正常退出)"
