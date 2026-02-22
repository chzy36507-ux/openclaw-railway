FROM node:22-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git openssh-client build-essential python3 python3-pip \
    g++ make ca-certificates nginx && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir huggingface_hub --break-system-packages

RUN npm install -g openclaw@latest --unsafe-perm

WORKDIR /app

COPY openclaw.json .
COPY sync.py .
COPY start.sh .

RUN chmod +x start.sh

EXPOSE 7860

CMD ["./start.sh"]