FROM node:22-slim

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    git openssh-client build-essential python3 python3-pip \
    g++ make ca-certificates && rm -rf /var/lib/apt/lists/*

# 安装 Python 依赖（huggingface_hub 用于数据持久化）
RUN pip3 install --no-cache-dir huggingface_hub --break-system-packages

# 安装 OpenClaw
RUN npm install -g openclaw@latest --unsafe-perm

# 设置工作目录
WORKDIR /app

# 复制文件
COPY openclaw.json .
COPY sync.py .
COPY start.sh .

# 给予执行权限
RUN chmod +x start.sh

# 暴露端口（HuggingFace 默认 7860）
EXPOSE 7860

# 启动命令
CMD ["./start.sh"]