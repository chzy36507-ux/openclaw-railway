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

# 动态设置 Slack Token 到配置文件
if [ -n "$SLACK_BOT_TOKEN" ] || [ -n "$SLACK_APP_TOKEN" ]; then
  if [ -f /app/openclaw.template.json ]; then
    # 使用 jq 或 sed 来替换 Token（这里使用简单的 sed）
    if [ -n "$SLACK_BOT_TOKEN" ]; then
      sed -i "s/\"botToken\": \"\"/\"botToken\": \"$SLACK_BOT_TOKEN\"/" /app/openclaw.template.json
    fi
    if [ -n "$SLACK_APP_TOKEN" ]; then
      sed -i "s/\"appToken\": \"\"/\"appToken\": \"$SLACK_APP_TOKEN\"/" /app/openclaw.template.json
    fi
    cp /app/openclaw.template.json /root/.openclaw/openclaw.json
  fi
fi

# 启动后台进程自动批准 Slack 配对请求
(
  sleep 30
  echo "Auto-approving Slack pairing requests..."
  for i in {1..10}; do
    # 获取待批准的配对列表并自动批准
    openclaw pairing list slack 2>/dev/null | while read line; do
      if echo "$line" | grep -q "pending"; then
        code=$(echo "$line" | awk '{print $NF}')
        echo "Approving pairing code: $code"
        openclaw pairing approve slack "$code" 2>/dev/null || true
      fi
    done
    sleep 10
  done
) &

# 启动 Nginx 反向代理（后台）
cat > /tmp/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 0.0.0.0:7860;
        server_name _;

        # 代理 OpenClaw Web UI 和 WebSocket
        location / {
            proxy_pass http://127.0.0.1:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 86400;
            proxy_connect_timeout 60;
            proxy_send_timeout 60;
        }

        # WebSocket 连接路径
        location /gateway {
            proxy_pass http://127.0.0.1:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 86400;
            proxy_connect_timeout 60;
            proxy_send_timeout 60;
        }

        # 静态资源路径
        location /__openclaw__/ {
            proxy_pass http://127.0.0.1:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 86400;
            proxy_connect_timeout 60;
            proxy_send_timeout 60;
        }

        # Slack 事件订阅
        location /slack/events {
            proxy_pass http://127.0.0.1:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
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