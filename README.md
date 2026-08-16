# AVF 虚拟机部署 DeepSeek Harness (DSH) 完整教程

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-22.19.0-339933?logo=node.js)](https://nodejs.org/)
[![Platform](https://img.shields.io/badge/Platform-AVF%20VM-4285F4?logo=android)](https://source.android.com/docs/core/virtualization)

> 在 Android AVF (Android Virtualization Framework) 虚拟机中完整部署 DeepSeek Harness 的实战指南，包含 root 和普通用户两种使用方式。

---

## 目录

- [简介](#简介)
- [环境要求](#环境要求)
- [快速开始（一键脚本）](#快速开始一键脚本)
- [详细步骤](#详细步骤)
  - [第一部分：Root 用户安装](#第一部分root-用户安装)
  - [第二部分：普通用户配置](#第二部分普通用户配置)
  - [第三部分：访问 DSH Web 界面](#第三部分访问-dsh-web-界面)
- [常见问题](#常见问题)
- [版本说明](#版本说明)
- [参考链接](#参考链接)

---

## 简介

[DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) 是 DeepSeek 官方推出的 AI 开发工具集。本教程帮助你在 **Android AVF 虚拟机**（Android 15+ 的 Linux 终端环境）中完整部署 DSH，涵盖：

- 国内镜像源配置（阿里云/清华）
- Node.js 22.19.0 二进制安装
- pnpm 包管理器配置
- node-pty ARM64 原生模块编译（关键步骤）
- root 和普通用户双模式支持
- 从 Android 主机访问 DSH Web UI

---

## 环境要求

| 项目 | 要求 |
|------|------|
| **设备** | 支持 AVF 的 Android 设备 |
| **Android 版本** | Android 15+ (启用 Linux 终端环境) |
| **架构** | ARM64 |
| **系统** | Debian 12 (bookworm) |
| **网络** | 需要访问国内镜像源（阿里云/清华） |

---

## 快速开始（一键脚本）

### Root 用户安装

```bash
#!/bin/bash
# ==============================================
# AVF 虚拟机安装 DSH（Root 用户部分）
# ==============================================

# 1. 换源
rm -rf /etc/apt/sources.list.d/*
tee /etc/apt/sources.list > /dev/null <<'EOF'
deb https://mirrors.aliyun.com/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.aliyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.aliyun.com/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
tee /etc/apt/mirrors/debian.list > /dev/null <<'EOF'
https://mirrors.aliyun.com/debian
EOF
tee /etc/apt/mirrors/debian-security.list > /dev/null <<'EOF'
https://mirrors.aliyun.com/debian-security
EOF
rm -rf /var/lib/apt/lists/*
apt clean
apt update

# 2. 安装 Node.js 22.19.0
apt install -y wget
cd /usr/local
wget https://mirrors.aliyun.com/nodejs-release/v22.19.0/node-v22.19.0-linux-arm64.tar.xz
tar -xf node-v22.19.0-linux-arm64.tar.xz
mv node-v22.19.0-linux-arm64 node
ln -sf /usr/local/node/bin/node /usr/local/bin/node
ln -sf /usr/local/node/bin/npm /usr/local/bin/npm
ln -sf /usr/local/node/bin/npx /usr/local/bin/npx

# 3. 安装 pnpm
npm config set registry https://registry.npmmirror.com
npm install -g pnpm@10 --registry=https://registry.npmmirror.com
ln -sf /usr/local/node/bin/pnpm /usr/local/bin/pnpm

# 4. 设置 pnpm 环境
export PNPM_HOME="$HOME/.local/share/pnpm"
mkdir -p $PNPM_HOME
export PATH="$PNPM_HOME:$PATH"
echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.bashrc
echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.bashrc
source ~/.bashrc
pnpm config set global-bin-dir $PNPM_HOME

# 5. 安装 DSH
pnpm add -g @deepseek-ai/dsh --registry=https://registry.npmmirror.com
ln -sf /usr/local/node/bin/dsh /usr/local/bin/dsh

# 6. 编译 node-pty（关键步骤）
apt install -y python3 make g++ build-essential
cd ~/.local/share/pnpm/global/5/.pnpm/node-pty@1.1.0/node_modules/node-pty
npm config set disturl https://mirrors.tuna.tsinghua.edu.cn/nodejs-release
npx node-gyp rebuild --nodedir=/usr/local/node
mkdir -p prebuilds/linux-arm64
cp build/Release/pty.node prebuilds/linux-arm64/

echo "Root 用户安装完成！"
```

### 普通用户配置（droid）

```bash
#!/bin/bash
# ==============================================
# AVF 虚拟机安装 DSH（普通用户部分）
# ==============================================

# 1. 切换到普通用户
su - droid

# 2. 安装 pnpm
npm install -g pnpm@10 --registry=https://registry.npmmirror.com

# 3. 设置 pnpm 环境
export PNPM_HOME="$HOME/.local/share/pnpm"
mkdir -p $PNPM_HOME
export PATH="$PNPM_HOME:$PATH"
echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.bashrc
echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.bashrc
source ~/.bashrc
pnpm config set global-bin-dir $PNPM_HOME

# 4. 安装 DSH
pnpm add -g @deepseek-ai/dsh --registry=https://registry.npmmirror.com
ln -sf /usr/local/node/bin/dsh /usr/local/bin/dsh

# 5. 复制 root 已编译的 pty.node
cd ~/.local/share/pnpm/global/5/.pnpm/node-pty@1.1.0/node_modules/node-pty
mkdir -p prebuilds/linux-arm64
sudo cp /root/.local/share/pnpm/global/5/.pnpm/node-pty@1.1.0/node_modules/node-pty/prebuilds/linux-arm64/pty.node prebuilds/linux-arm64/
sudo chown $USER:$USER prebuilds/linux-arm64/pty.node

# 6. 启动
dsh web
```

---

## 详细步骤

### 第一部分：Root 用户安装

#### 1.1 配置 apt 国内源（阿里源）

AVF 虚拟机使用 `/etc/apt/mirrors/` 目录管理镜像源，需要特殊配置。

```bash
# 清理旧配置
rm -rf /etc/apt/sources.list.d/*

# 配置 apt 源
tee /etc/apt/sources.list > /dev/null <<'EOF'
deb https://mirrors.aliyun.com/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.aliyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.aliyun.com/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# 配置 AVF 专用镜像文件
tee /etc/apt/mirrors/debian.list > /dev/null <<'EOF'
https://mirrors.aliyun.com/debian
EOF

tee /etc/apt/mirrors/debian-security.list > /dev/null <<'EOF'
https://mirrors.aliyun.com/debian-security
EOF

# 更新源
rm -rf /var/lib/apt/lists/*
apt clean
apt update
```

#### 1.2 安装 Node.js 22.19.0（阿里云镜像）

```bash
# 安装 wget
apt install -y wget

# 从阿里云镜像下载
cd /usr/local
wget https://mirrors.aliyun.com/nodejs-release/v22.19.0/node-v22.19.0-linux-arm64.tar.xz

# 解压并配置
tar -xf node-v22.19.0-linux-arm64.tar.xz
mv node-v22.19.0-linux-arm64 node

# 创建软链接
ln -sf /usr/local/node/bin/node /usr/local/bin/node
ln -sf /usr/local/node/bin/npm /usr/local/bin/npm
ln -sf /usr/local/node/bin/npx /usr/local/bin/npx

# 验证
node --version   # v22.19.0
npm --version    # 10.9.0
```

#### 1.3 安装 pnpm

```bash
# 配置 npm 国内镜像
npm config set registry https://registry.npmmirror.com

# 安装 pnpm（使用兼容版本）
npm install -g pnpm@10 --registry=https://registry.npmmirror.com

# 创建软链接
ln -sf /usr/local/node/bin/pnpm /usr/local/bin/pnpm

# 验证
pnpm --version   # 10.x.x
```

> 注意：pnpm 11.x 需要 Node.js >= 22.13，如果你的 Node.js 版本较低，请安装 pnpm@10。

#### 1.4 设置 pnpm 全局目录

```bash
export PNPM_HOME="$HOME/.local/share/pnpm"
mkdir -p $PNPM_HOME
export PATH="$PNPM_HOME:$PATH"

echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.bashrc
echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.bashrc
source ~/.bashrc

pnpm config set global-bin-dir $PNPM_HOME
```

#### 1.5 安装 DSH

```bash
pnpm add -g @deepseek-ai/dsh --registry=https://registry.npmmirror.com
ln -sf /usr/local/node/bin/dsh /usr/local/bin/dsh
```

#### 1.6 编译 node-pty（关键步骤）

DSH 依赖的 `node-pty` 没有 Linux ARM64 预编译版本，需要手动编译。

```bash
# 安装编译依赖
apt install -y python3 make g++ build-essential

# 进入 node-pty 目录
cd ~/.local/share/pnpm/global/5/.pnpm/node-pty@1.1.0/node_modules/node-pty

# 配置国内镜像
npm config set disturl https://mirrors.tuna.tsinghua.edu.cn/nodejs-release

# 编译
npx node-gyp rebuild --nodedir=/usr/local/node

# 复制编译产物
mkdir -p prebuilds/linux-arm64
cp build/Release/pty.node prebuilds/linux-arm64/

# 验证
ls -la prebuilds/linux-arm64/pty.node  # 应该显示 81232 字节
```

#### 1.7 验证 Root 用户启动

```bash
dsh web
# 输出: dsh web: http://127.0.0.1:3080
```

---

### 第二部分：普通用户配置

#### 2.1 切换到普通用户

```bash
su - droid
```

#### 2.2 安装 pnpm 并配置环境

```bash
npm install -g pnpm@10 --registry=https://registry.npmmirror.com

export PNPM_HOME="$HOME/.local/share/pnpm"
mkdir -p $PNPM_HOME
export PATH="$PNPM_HOME:$PATH"
echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.bashrc
echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.bashrc
source ~/.bashrc

pnpm config set global-bin-dir $PNPM_HOME
```

#### 2.3 安装 DSH

```bash
pnpm add -g @deepseek-ai/dsh --registry=https://registry.npmmirror.com
ln -sf /usr/local/node/bin/dsh /usr/local/bin/dsh
```

#### 2.4 复制 Root 已编译的 pty.node

```bash
cd ~/.local/share/pnpm/global/5/.pnpm/node-pty@1.1.0/node_modules/node-pty
mkdir -p prebuilds/linux-arm64
sudo cp /root/.local/share/pnpm/global/5/.pnpm/node-pty@1.1.0/node_modules/node-pty/prebuilds/linux-arm64/pty.node prebuilds/linux-arm64/
sudo chown droid:droid prebuilds/linux-arm64/pty.node
ls -la prebuilds/linux-arm64/pty.node
```

#### 2.5 启动 DSH

```bash
dsh web
# 输出: dsh web: http://127.0.0.1:3080
```

---

### 第三部分：访问 DSH Web 界面

| 场景 | 访问方式 |
|------|----------|
| 在 AVF 虚拟机内（有 GUI） | 浏览器打开 http://127.0.0.1:3080 |
| 从 Android 主机访问 | adb forward tcp:3080 tcp:3080，然后访问 http://127.0.0.1:3080 |
| 从其他设备访问 | 需要配置网络或端口转发 |

#### 首次使用设置

1. 打开浏览器访问 http://127.0.0.1:3080
2. 进入 设置 -> 模型
3. 填入你的 DeepSeek API Key
4. 选择工作目录（Workspace）

---

## 常见问题

### Q: Node.js 下载 404 怎么办？

换用其他镜像源：

```bash
# 官方源
wget https://nodejs.org/dist/v22.19.0/node-v22.19.0-linux-arm64.tar.xz

# 清华源
wget https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/v22.19.0/node-v22.19.0-linux-arm64.tar.xz
```

### Q: pnpm 报错 Node 版本过低？

安装 pnpm@10（兼容 Node 22.11+）：

```bash
npm install -g pnpm@10 --registry=https://registry.npmmirror.com
```

### Q: node-pty 编译失败？

确保已安装编译依赖：

```bash
apt install -y python3 make g++ build-essential
npm config set disturl https://mirrors.tuna.tsinghua.edu.cn/nodejs-release
npx node-gyp rebuild --nodedir=/usr/local/node
```

### Q: 普通用户找不到 dsh 命令？

检查并添加 PATH：

```bash
export PATH=/usr/local/bin:$PATH
echo 'export PATH=/usr/local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Q: DSH 找不到 pty.node？

从 root 复制已编译的文件：

```bash
sudo cp /root/.local/share/pnpm/global/5/.pnpm/node-pty@1.1.0/node_modules/node-pty/prebuilds/linux-arm64/pty.node /home/你的用户名/.local/share/pnpm/global/5/.pnpm/node-pty@1.1.0/node_modules/node-pty/prebuilds/linux-arm64/
sudo chown 用户名:用户名 /home/你的用户名/.local/share/pnpm/global/5/.pnpm/node-pty@1.1.0/node_modules/node-pty/prebuilds/linux-arm64/pty.node
```

### Q: 权限被拒绝怎么办？

使用 sudo 复制文件，然后 chown 修改所有者：

```bash
sudo cp [源文件] [目标目录]
sudo chown $USER:$USER [目标文件]
```

### Q: npm 下载慢？

配置国内镜像：

```bash
npm config set registry https://registry.npmmirror.com
```

---

## 版本说明

| 组件 | 版本 | 说明 |
|------|------|------|
| Node.js | 22.19.0 | 从阿里云镜像下载 |
| npm | 10.9.0 | 随 Node.js 自带 |
| pnpm | 10.x | 兼容 Node 22.11+ |
| DSH | latest | 从 npm 镜像安装 |
| node-pty | 1.1.0 | 需手动编译 ARM64 |
| Debian | 12 (bookworm) | AVF 默认系统 |

---

## 参考链接

- [DeepSeek Harness GitHub](https://github.com/deepseek-ai/deepseek-harness)
- [Android AVF 官方文档](https://source.android.com/docs/core/virtualization)
- [Node.js 官方下载](https://nodejs.org/)
- [阿里云镜像站](https://mirrors.aliyun.com/)
- [清华大学镜像站](https://mirrors.tuna.tsinghua.edu.cn/)

---

## License

MIT License

---

## 支持

如果这个教程对你有帮助，请给个 Star 支持一下！

---

Happy Coding!
