#!/bin/bash
set -e

install -m 600 /dev/null /etc/grafana/smtp-password
aws ssm get-parameter \
  --region '${aws_region}' \
  --name '${smtp_password_parameter_arn}' \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text > /etc/grafana/smtp-password
chown grafana:grafana /etc/grafana/smtp-password

cat > /etc/grafana/grafana.ini <<'EOF'
[smtp]
enabled = true
host = smtp.gmail.com:587
user = ${alert_email}
password = $__file{/etc/grafana/smtp-password}
from_address = ${alert_email}
startTLS_policy = MandatoryStartTLS
EOF

mkdir -p /etc/grafana/provisioning/alerting

echo '${contact_points}' | base64 -d > /etc/grafana/provisioning/alerting/contact-points.yaml
echo '${alert_rules}' | base64 -d | gzip -d > /etc/grafana/provisioning/alerting/alert-rules.yaml

echo '${alb_4xx_dashboard}' | base64 -d | gzip -d > /var/lib/grafana/dashboards/alb-4xx.json
echo '${alb_5xx_dashboard}' | base64 -d | gzip -d > /var/lib/grafana/dashboards/alb-5xx.json
echo '${response_time_dashboard}' | base64 -d | gzip -d > /var/lib/grafana/dashboards/response-time.json
echo '${cpu_dashboard}' | base64 -d | gzip -d > /var/lib/grafana/dashboards/cpu.json
echo '${memory_dashboard}' | base64 -d | gzip -d > /var/lib/grafana/dashboards/memory.json
echo '${root_disk_dashboard}' | base64 -d | gzip -d > /var/lib/grafana/dashboards/root-disk.json

systemctl enable --now prometheus grafana-server

echo '${webui_script}' | base64 -d > /tmp/open-webui.sh
bash /tmp/open-webui.sh '${ollama_url}'