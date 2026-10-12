#!/bin/bash

# 确保脚本以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限运行此脚本。例如：sudo ./setup_scraper.sh"
  exit 1
fi

echo "=========================================="
echo "RK3399Pro (Debian 10 ARM64) 抖音爬虫环境自动配置脚本"
echo "=========================================="

# 1. 更新 apt 源
echo "正在更新 apt 源..."
apt-get update -y

# 2. 安装基础依赖
echo "正在安装基础依赖 (python3, python3-pip)..."
apt-get install -y python3 python3-pip

# 3. 安装 Python 依赖包
echo "正在安装 requirements.txt 中的 Python 依赖包..."
# 尝试使用 pip3 安装，添加 --break-system-packages 以适配新版系统
if [ -f "requirements.txt" ]; then
    pip3 install --break-system-packages -r requirements.txt
else
    echo "未找到 requirements.txt，尝试直接安装 playwright, requests 等依赖..."
    pip3 install --break-system-packages playwright requests Pillow transformers torch
fi

# 4. 安装 Playwright 浏览器及系统依赖
echo "正在安装 Playwright 系统依赖..."
playwright install-deps

echo "正在安装 Playwright Chromium 浏览器..."
playwright install chromium

echo "=========================================="
echo "环境配置完成！"
echo "=========================================="
