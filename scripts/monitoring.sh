#!/bin/bash
set -e

dnf install -y curl tar gzip shadow-utils

#prometheus
VERSION="3.14.0"

curl -fsSL "https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-amd64.tar.gz" -o /tmp/prometheus.tar.gz

echo "f665c6da19eb7ba399c915d30c7d9793c9b417bf8a749b504bc470678631478d  /tmp/prometheus.tar.gz" | sha256sum -c -

tar -xzf /tmp/prometheus.tar.gz -C /tmp
install -m 755 /tmp/prometheus-${VERSION}.linux-amd64/prometheus /usr/local/bin/

useradd -r -s /sbin/nologin prometheus
mkdir -p /etc/prometheus /var/lib/prometheus
chown prometheus:prometheus /var/lib/prometheus

cat > /etc/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]
EOF

cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus --storage.tsdb.retention.size=2GB --web.listen-address=0.0.0.0:9090 --web.enable-remote-write-receiver
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

#grafana
curl -fsSL https://rpm.grafana.com/gpg.key -o /tmp/grafana-gpg.key
rpm --import /tmp/grafana-gpg.key

cat > /etc/yum.repos.d/grafana.repo <<'EOF'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
EOF

dnf install -y grafana

#gt_to_pms
mkdir -p /etc/grafana/provisioning/datasources

cat > /etc/grafana/provisioning/datasources/prometheus.yml <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://127.0.0.1:9090
    isDefault: true
EOF

cat > /etc/grafana/provisioning/datasources/cloudwatch.yml <<'EOF'
apiVersion: 1
datasources:
  - name: CloudWatch
    type: cloudwatch
    jsonData:
      authType: default
      defaultRegion: us-east-1
EOF

systemctl daemon-reload
systemctl enable --now prometheus grafana-server
