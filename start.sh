#!/bin/bash
set -e

# 限制 Node.js 堆内存为 256MB（Railway 免费实例上限约 512MB，给系统留 256MB）
export NODE_OPTIONS="--max-old-space-size=256"

# 1. 创建必要目录
mkdir -p /data/workspace
mkdir -p /root/.openclaw/agents/main/sessions
mkdir -p /root/.openclaw/credentials
mkdir -p /root/.openclaw/sessions

# 2. 将 .openclaw 软链接到 /data 以实现持久化
if [ ! -L /root/.openclaw ]; then
  rm -rf /root/.openclaw
  ln -s /data/.openclaw /root/.openclaw
fi

# 3. 初始化 OpenClaw（如果尚未初始化）
if [ ! -f /root/.openclaw/openclaw.json ]; then
  openclaw init --non-interactive
  # 复制我们的配置
  cp /app/openclaw.json /root/.openclaw/openclaw.json
fi

# 4. 启动 OpenClaw Gateway
exec openclaw gateway start --port 3000 --bind 0.0.0.0
