FROM node:22-slim

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    git openssh-client build-essential python3 python3-pip \
    g++ make ca-certificates && rm -rf /var/lib/apt/lists/*

# 安装 OpenClaw
RUN npm install -g openclaw@latest --unsafe-perm

# 设置工作目录
WORKDIR /app

# 复制文件
COPY openclaw.json .
COPY start.sh .

# 给予执行权限
RUN chmod +x start.sh

# 暴露端口（Railway 会自动设置 PORT 环境变量，但我们可以默认 3000）
EXPOSE 3000

# 启动命令
CMD ["./start.sh"]
