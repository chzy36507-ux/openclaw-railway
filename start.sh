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

# 启动 Nginx 反向代理（后台）
cat > /tmp/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 0.0.0.0:7860;
        
        location / {
            proxy_pass http://127.0.0.1:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_read_timeout 86400;
            proxy_connect_timeout 60;
            proxy_send_timeout 60;
        }
    }
}
EOF

# 检查是否安装 nginx
if ! command -v nginx &> /dev/null; then
  echo "Installing nginx..."
  apt-get update && apt-get install -y nginx
fi

# 启动 nginx
nginx -c /tmp/nginx.conf

echo "Nginx started on 0.0.0.0:7860"
echo "Starting OpenClaw Gateway..."

# 启动 OpenClaw 网关（完全无参数）
exec openclaw gateway