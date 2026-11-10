#!/bin/bash
set -e

dnf install -y docker jq postgresql16
systemctl enable --now docker

webui_credentials=$(aws secretsmanager get-secret-value \
  --secret-id '${webui_secret_arn}' \
  --query SecretString \
  --output text)

db_username=$(jq -r '.db_username' <<< "$webui_credentials")
db_password=$(jq -r '.db_password' <<< "$webui_credentials")
webui_secret_key=$(jq -r '.webui_secret_key' <<< "$webui_credentials")

master_credentials=$(aws secretsmanager get-secret-value \
  --secret-id '${rds_master_secret_arn}' \
  --query SecretString \
  --output text)

master_username=$(jq -r '.username' <<< "$master_credentials")
master_password=$(jq -r '.password' <<< "$master_credentials")

PGPASSWORD="$master_password" psql \
  -h '${db_host}' \
  -U "$master_username" \
  -d '${db_name}' \
  -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$db_username') THEN
    CREATE ROLE "$db_username" LOGIN PASSWORD '$db_password';
  ELSE
    ALTER ROLE "$db_username" WITH PASSWORD '$db_password';
  END IF;
END
\$\$;

GRANT CREATE ON SCHEMA public TO "$db_username";
SQL

docker run -d \
  --name open-webui \
  --restart always \
  -p 80:8080 \
  -e OLLAMA_BASE_URL="${ollama_url}" \
  -e WEBUI_SECRET_KEY="$webui_secret_key" \
  -e DATABASE_URL="postgresql://$db_username:$db_password@${db_host}:5432/${db_name}" \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:slim
