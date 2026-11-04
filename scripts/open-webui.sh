#!/bin/bash
set -e

dnf install -y docker
systemctl enable --now docker

if [ ! -f /etc/open-webui-secret ]; then
  openssl rand -hex 32 > /etc/open-webui-secret
  chmod 600 /etc/open-webui-secret
fi

docker rm -f open-webui 2>/dev/null || true
docker run -d \
  --name open-webui \
  --restart always \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL="$1" \
  -e WEBUI_SECRET_KEY="$(cat /etc/open-webui-secret)" \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:slim
