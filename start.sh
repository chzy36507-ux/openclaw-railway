#!/bin/bash
set -e

mkdir -p /data/workspace
mkdir -p /data/.openclaw/agents/main/sessions
mkdir -p /data/.openclaw/credentials
mkdir -p /data/.openclaw/sessions

if [ ! -L /root/.openclaw ]; then
  rm -rf /root/.openclaw
  ln -s /data/.openclaw /root/.openclaw
fi

# 暂时跳过恢复
# python3 /app/sync.py restore

if [ ! -f /root/.openclaw/openclaw.json ]; then
  cp /app/openclaw.json /root/.openclaw/openclaw.json
fi

openclaw doctor --fix || true

export NODE_OPTIONS="--max-old-space-size=1024"

# 无参数启动
exec openclaw gateway serve