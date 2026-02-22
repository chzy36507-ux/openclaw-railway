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

# 修正配置文件权限
chmod 600 /root/.openclaw/openclaw.json
chmod 700 /root/.openclaw

openclaw doctor --fix || true

export NODE_OPTIONS="--max-old-space-size=1024"

# 检查是否安装 nginx
if ! command -v nginx &> /dev/null; then
  echo "Installing nginx..."
  apt-get update && apt-get install -y nginx
fi

# 复制 nginx 配置文件
cp /app/nginx.conf /etc/nginx/sites-available/default

# 启动 nginx
nginx

echo "Nginx started on 0.0.0.0:7860"
echo "Starting OpenClaw Gateway..."

# 启动 OpenClaw 网关（完全无参数）
exec openclaw gateway