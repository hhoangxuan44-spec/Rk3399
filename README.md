# RK3399Pro (Debian 10 ARM64) 桌面自动化配置与重构脚本

本仓库包含一套为基于 Debian 10 ARM64 的 RK3399Pro 平台量身定制的桌面环境自动化配置脚本。
该脚本设计包含防重试机制并具备清晰易懂的中文终端输出功能。

## 功能列表

1. 更新系统包管理器的 apt 源。
2. 安装基础中文支持（fonts-noto-cjk、并配置系统 locale 为 zh_CN.UTF-8）。
3. 安装轻量级中文输入法（fcitx 及其拼音模块）。
4. 一键安装日常常用及开发相关的基础工具与依赖（curl, git, python3, pip, htop, build-essential）。
5. 自动检测用户的桌面环境（目前支持并自动检测 XFCE 与 LXDE 轻量桌面），将 `assets/` 目录里的壁纸静默应用为当前默认系统桌面。

## 运行方法

在 Debian 10 系统的终端内，只需以 `root` 权限一键运行此配置脚本。

1. 克隆或下载本项目到本地（如果没有 `git`，可以下载 ZIP 包并解压）：

```bash
git clone https://github.com/your-username/rk3399pro-desktop-setup.git
cd rk3399pro-desktop-setup
```

2. 在终端使用以下一行命令一键执行：

```bash
sudo ./setup_desktop.sh
```

**提示：** 脚本执行成功后，请根据提示重启系统以使中文环境和所有桌面配置完全生效。