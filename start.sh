#!/bin/bash
set -e

# 1. 创建必要目录
mkdir -p /data/workspace
mkdir -p /data/.openclaw/agents/main/sessions
mkdir -p /data/.openclaw/credentials
mkdir -p /data/.openclaw/sessions

# 2. 将 .openclaw 软链接到 /data 以实现持久化
if [ ! -L /root/.openclaw ]; then
  rm -rf /root/.openclaw
  ln -s /data/.openclaw /root/.openclaw
fi

# 3. 恢复历史数据（如果存在）—— 首次运行会失败，这是正常的
python3 /app/sync.py restore

# 4. 确保 openclaw.json 在正确的位置
if [ ! -f /root/.openclaw/openclaw.json ]; then
  cp /app/openclaw.json /root/.openclaw/openclaw.json
fi

# 5. 修复配置（自动修正错误）
openclaw doctor --fix || true

# 6. 限制 Node.js 内存（防止 OOM）
export NODE_OPTIONS="--max-old-space-size=1024"

# 7. 启动 OpenClaw Gateway
exec openclaw gateway start --port 7860 --bind 0.0.0.0