# 1. 基础镜像
FROM debian:bookworm-slim

# 2. 避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# 3. 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget curl ca-certificates \
        python3 make g++ build-essential && \
    rm -rf /var/lib/apt/lists/*

# 4. 安装 Node.js 22.19.0 (ARM64)
ENV NODE_VERSION=22.19.0
RUN cd /usr/local && \
    wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz && \
    tar -xf node-v${NODE_VERSION}-linux-arm64.tar.xz && \
    mv node-v${NODE_VERSION}-linux-arm64 node && \
    ln -sf /usr/local/node/bin/node /usr/local/bin/node && \
    ln -sf /usr/local/node/bin/npm  /usr/local/bin/npm && \
    ln -sf /usr/local/node/bin/npx  /usr/local/bin/npx && \
    rm node-v${NODE_VERSION}-linux-arm64.tar.xz

# 5. 安装 PNPM
RUN npm install -g pnpm@10 && \
    ln -sf /usr/local/node/bin/pnpm /usr/local/bin/pnpm

# 6. PNPM 全局环境
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="${PNPM_HOME}:${PATH}"
RUN pnpm config set global-bin-dir ${PNPM_HOME}

# 7. 全局安装 DSH
RUN pnpm add -g @deepseek-ai/dsh && \
    ln -sf /usr/local/node/bin/dsh /usr/local/bin/dsh

# 8.【核心】用 shell 通配符定位 node-pty，现场重编译
# 用 pnpm 全局存储路径通配符
RUN PTY_DIR=$(echo ${PNPM_HOME}/global/*/.pnpm/node-pty@*/node_modules/node-pty) && \
    echo "✅ Found node-pty at: ${PTY_DIR}" && \
    cd "${PTY_DIR}" && \
    npx node-gyp rebuild --nodedir=/usr/local/node && \
    mkdir -p prebuilds/linux-arm64 && \
    cp build/Release/pty.node prebuilds/linux-arm64/ && \
    echo "✅ node-pty recompiled successfully!"

# 9. 暴露端口
EXPOSE 3080

# 10. 启动命令
CMD ["dsh", "web"]