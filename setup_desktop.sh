#!/bin/bash

# 确保脚本以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限运行此脚本。例如：sudo ./setup_desktop.sh"
  exit 1
fi

echo "=========================================="
echo "RK3399Pro (Debian 10 ARM64) 桌面自动化配置与重构脚本"
echo "=========================================="

# 防重试机制：检查包是否已安装
is_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

# 1. 更新 apt 源
echo "[1/6] 正在更新 apt 源..."
apt-get update -y

# 2. 安装基础中文支持
echo "[2/6] 正在配置基础中文支持 (fonts-noto-cjk, locales)..."
if ! is_installed "fonts-noto-cjk" || ! is_installed "locales"; then
    apt-get install -y fonts-noto-cjk locales
else
    echo "基础中文支持包已安装，跳过。"
fi

# 配置中文 locale
if grep -q "^# zh_CN.UTF-8 UTF-8" /etc/locale.gen; then
    echo "启用 zh_CN.UTF-8..."
    sed -i 's/^# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    update-locale LANG=zh_CN.UTF-8
    echo "locale 设置为 zh_CN.UTF-8 完成。"
else
    echo "zh_CN.UTF-8 已经是启用状态或已配置。"
fi

# 3. 安装轻量中文输入法
echo "[3/6] 正在安装轻量中文输入法 (fcitx, fcitx-pinyin)..."
if ! is_installed "fcitx" || ! is_installed "fcitx-pinyin"; then
    apt-get install -y fcitx fcitx-pinyin
    # 简单的默认输入法设置
    if command -v im-config >/dev/null 2>&1; then
        im-config -n fcitx
    fi
else
    echo "中文输入法 fcitx 及 fcitx-pinyin 已安装，跳过。"
fi

# 4. 安装常用基础工具和开发依赖
echo "[4/6] 正在安装常用基础工具和开发依赖..."
DEPS=("curl" "git" "python3" "python3-pip" "htop" "build-essential")
for pkg in "${DEPS[@]}"; do
    if ! is_installed "$pkg"; then
        echo "安装 $pkg ..."
        apt-get install -y "$pkg"
    else
        echo "$pkg 已安装，跳过。"
    fi
done

# 5. 自动检测并应用默认桌面壁纸
echo "[5/6] 正在配置桌面壁纸..."

# 获取脚本所在的当前绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
WALLPAPER_PATH="$SCRIPT_DIR/assets/default_wallpaper.jpg"

if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "警告：未找到壁纸图片 $WALLPAPER_PATH，请确保 assets/default_wallpaper.jpg 存在。"
else
    # 遍历 /home/ 下的所有用户目录（排除系统默认目录）
    for user_dir in /home/*; do
        if [ -d "$user_dir" ]; then
            user_name=$(basename "$user_dir")

            # XFCE 壁纸配置
            if [ -d "$user_dir/.config/xfce4/xfconf/xfce-perchannel-xml" ]; then
                echo "检测到 $user_name 用户使用 XFCE，正在应用壁纸..."
                xfce_config_file="$user_dir/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"

                # 如果配置文件存在，尝试替换或者添加 (这里提供一种简单的sed替换或追加思路，实际可能需要更复杂的xml处理)
                if [ -f "$xfce_config_file" ]; then
                    # 简单通过sed修改现有的last-image路径
                    sed -i "s|<property name=\"last-image\" type=\"string\" value=\".*\"/>|<property name=\"last-image\" type=\"string\" value=\"$WALLPAPER_PATH\"/>|g" "$xfce_config_file"
                else
                    # 如果没有桌面配置文件，可不执行或创建基本结构（这里选择提示）
                    echo "用户 $user_name 没有现有的 xfce4-desktop.xml，建议手动应用或使用 xfconf-query。"
                fi
                chown -R "$user_name:$user_name" "$user_dir/.config/xfce4"
            fi

            # LXDE 壁纸配置
            if [ -d "$user_dir/.config/pcmanfm/LXDE" ]; then
                echo "检测到 $user_name 用户使用 LXDE，正在应用壁纸..."
                lxde_config_file="$user_dir/.config/pcmanfm/LXDE/desktop-items-0.conf"

                if [ -f "$lxde_config_file" ]; then
                    sed -i "s|^wallpaper=.*|wallpaper=$WALLPAPER_PATH|g" "$lxde_config_file"
                else
                    echo "[*]" > "$lxde_config_file"
                    echo "wallpaper=$WALLPAPER_PATH" >> "$lxde_config_file"
                    echo "wallpaper_mode=stretch" >> "$lxde_config_file"
                fi
                chown -R "$user_name:$user_name" "$user_dir/.config/pcmanfm"
            fi
        fi
    done
    echo "壁纸配置尝试完成。"
fi

echo "[6/6] 所有任务执行完毕！"
echo "=========================================="
echo "配置完成，建议重启系统使所有设置生效 (reboot)。"
