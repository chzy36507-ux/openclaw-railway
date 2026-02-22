---
title: OpenClaw Gateway
colorFrom: blue
colorTo: purple
sdk: docker
pinned: false
---

# OpenClaw HuggingFace Space

OpenClaw AI Agent Gateway on HuggingFace Spaces.

## Features

- Gateway server with token authentication
- Slack integration support
- HuggingFace dataset backup/restore
- Nginx reverse proxy for external access

## Environment Variables

Set these in your Space settings:

- `HF_TOKEN`: Your HuggingFace Access Token with write permissions (for backup/restore)

## Configuration

Edit `openclaw.json` to customize:
- Gateway port (default: 7860)
- Authentication token
- Agent settings
- Channel integrations

## Deployment

1. Configure environment variables
2. Push code to HuggingFace Space
3. Space will automatically rebuild with Docker
4. Access via Space URL: `https://yanscy-openclaw.hf.space`

## Architecture

- Nginx listens on `0.0.0.0:7860` (external)
- OpenClaw Gateway listens on `127.0.0.1:7860` (internal)
- Nginx proxies all requests to OpenClaw

## Logs

Check Space logs for startup status and runtime information.