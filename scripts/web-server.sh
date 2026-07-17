#!/bin/bash

set -e

AWS_REGION="${AWS_REGION}"
DB_SECRET_ARN="${DB_SECRET_ARN}"
SMTP_SECRET_ARN="${SMTP_SECRET_ARN}"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"
DNS_NAME="${DNS_NAME}"

sudo apt update
sudo apt-get install -y curl wget unzip jq

### Install AWS CLI

cd /tmp

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q awscliv2.zip
sudo ./aws/install

### Get database secret

DB_SECRET_JSON=$(aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$DB_SECRET_ARN" \
  --query SecretString \
  --output text)

DB_USERNAME=$(echo "$DB_SECRET_JSON" | jq -r '.db_username')
DB_PASSWORD=$(echo "$DB_SECRET_JSON" | jq -r '.db_password')

### Get SMTP secret

SMTP_SECRET_JSON=$(aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SMTP_SECRET_ARN" \
  --query SecretString \
  --output text)

SMTP_USERNAME=$(echo "$SMTP_SECRET_JSON" | jq -r '.smtp_username')
SMTP_PASSWORD=$(echo "$SMTP_SECRET_JSON" | jq -r '.smtp_password')
SMTP_FROM=$(echo "$SMTP_SECRET_JSON" | jq -r '.smtp_from')
SMTP_TO=$(echo "$SMTP_SECRET_JSON" | jq -r '.smtp_to')

### Install Alert Manager

wget \
  "https://github.com/prometheus/alertmanager/releases/download/v0.33.1/alertmanager-0.33.1.linux-amd64.tar.gz"

tar xzf \
  "alertmanager-0.33.1.linux-amd64.tar.gz"

sudo useradd \
  --system \
  --no-create-home \
  --shell /usr/sbin/nologin \
  alertmanager || true

sudo install \
  -m 0755 \
  "alertmanager-0.33.1.linux-amd64/alertmanager" \
  /usr/local/bin/alertmanager

sudo install \
  -m 0755 \
  "alertmanager-0.33.1.linux-amd64/amtool" \
  /usr/local/bin/amtool

sudo mkdir -p /etc/alertmanager/secrets
sudo mkdir -p /var/lib/alertmanager

### Create SMTP password file

sudo install \
  -d \
  -o root \
  -g alertmanager \
  -m 0750 \
  /etc/alertmanager/secrets

printf '%s' "$SMTP_PASSWORD" \
  | sudo tee /etc/alertmanager/secrets/smtp_password \
  > /dev/null

sudo chown \
  root:alertmanager \
  /etc/alertmanager/secrets/smtp_password

sudo chmod \
  0640 \
  /etc/alertmanager/secrets/smtp_password

sudo tee /etc/alertmanager/alertmanager.yaml > /dev/null <<EOF
global:
  resolve_timeout: 5m

  smtp_smarthost: "smtp.gmail.com:587"
  smtp_from: "$SMTP_FROM"
  smtp_auth_username: "$SMTP_USERNAME"
  smtp_auth_password_file: "/etc/alertmanager/secrets/smtp_password"
  smtp_require_tls: true

route:
  receiver: email-default

  group_by:
    - alertname
    - environment
    - severity

  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

receivers:
  - name: email-default
    email_configs:
      - to: "$SMTP_TO"
        send_resolved: true

        headers:
          Subject: '[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }}'
EOF

sudo chown \
  root:alertmanager \
  /etc/alertmanager/alertmanager.yaml

sudo chmod \
  0640 \
  /etc/alertmanager/alertmanager.yaml

sudo chown -R alertmanager:alertmanager /var/lib/alertmanager

echo "[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
Type=simple

User=alertmanager
Group=alertmanager

ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yaml \
    --storage.path=/var/lib/alertmanager \
    --web.listen-address=127.0.0.1:9093

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/alertmanager.service

### Install Prometheus

wget https://github.com/prometheus/prometheus/releases/download/v3.13.0/prometheus-3.13.0.linux-amd64.tar.gz
tar xvf prometheus-3.13.0.linux-amd64.tar.gz

sudo install \
    -m 0755 \
    "prometheus-3.13.0.linux-amd64/prometheus" \
    /usr/local/bin/prometheus

sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus

echo "global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "127.0.0.1:9093"

scrape_configs:
  - job_name: "llm-node-exporter"
  
    ec2_sd_configs:
      - region: "eu-central-1"
        port: 9100
        refresh_interval: 60s
  
        filters:
          - name: instance-state-name
            values: ["running"]
  
          - name: tag:Role
            values: ["llm"]
  
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Role]
        target_label: role
  
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
  
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance_id
  
      - source_labels: [__meta_ec2_private_ip]
        target_label: private_ip
  
      - source_labels: [__meta_ec2_availability_zone]
        target_label: availability_zone
  
      - source_labels:
          - __meta_ec2_tag_Name
          - __meta_ec2_instance_id
        separator: ' - '
        target_label: display_name

  - job_name: "bastion-node-exporter"

    ec2_sd_configs:
      - region: "eu-central-1"
        port: 9100
        refresh_interval: 60s

        filters:
          - name: instance-state-name
            values: ["running"]

          - name: tag:Role
            values: ["bastion"]

    relabel_configs:
      - source_labels: [__meta_ec2_tag_Role]
        target_label: role

      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name

      - source_labels: [__meta_ec2_instance_id]
        target_label: instance_id

  - job_name: "web-server-node-exporter"

    ec2_sd_configs:
      - region: "eu-central-1"
        port: 9100
        refresh_interval: 60s

        filters:
          - name: instance-state-name
            values: ["running"]

          - name: tag:Role
            values: ["web-server"]

    relabel_configs:
      - source_labels: [__meta_ec2_tag_Role]
        target_label: role

      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name

      - source_labels: [__meta_ec2_instance_id]
        target_label: instance_id" > /etc/prometheus/prometheus.yml

echo "[Unit]
Description=Prometheus Monitoring
After=network-online.target
Wants=network-online.target

[Service]
Type=simple

ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus \
    --web.listen-address=:9090

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/prometheus.service

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

### Install Grafana

sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/grafana-enterprise/release/13.1.0/grafana-enterprise_13.1.0_28013217238_linux_amd64.deb
sudo dpkg -i grafana-enterprise_13.1.0_28013217238_linux_amd64.deb

sudo sed -i 's/^;http_port = 3000$/http_port = 5000/' /etc/grafana/grafana.ini

mkdir -p /etc/grafana/provisioning/datasources
mkdir -p /etc/grafana/provisioning/dashboards
mkdir -p /var/lib/grafana/dashboards

# sudo systemctl daemon-reload
# sudo systemctl enable grafana-server
# sudo systemctl start grafana-server

### Install Node Exporter

wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
tar xzf node_exporter-1.10.2.linux-amd64.tar.gz

sudo install \
    -m 0755 \
    "node_exporter-1.10.2.linux-amd64/node_exporter" \
    /usr/local/bin/node_exporter

echo "[Unit]
Description=Prometheus Node Exporter
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --collector.systemd \
    --collector.systemd.unit-include='(prometheus|grafana-server|node_exporter|docker|alertmanager)\.service'

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/node_exporter.service

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

### Install Docker & Open WebUI

# Add Docker's official GPG key:
sudo apt update

sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

DB_USERNAME_URL=$(printf '%s' "$DB_USERNAME" | jq -sRr @uri)
DB_PASSWORD_URL=$(printf '%s' "$DB_PASSWORD" | jq -sRr @uri)

DATABASE_URL="postgresql://$DB_USERNAME_URL:$DB_PASSWORD_URL@$DB_HOST:$DB_PORT/$DB_NAME"

sudo docker run -d \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL="http://$DNS_NAME" \
  -e DATABASE_URL="$DATABASE_URL" \
  -e VECTOR_DB="pgvector" \
  -v open-webui-data:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main-slim

unset DB_SECRET_JSON
unset DB_USERNAME
unset DB_PASSWORD
unset DB_USERNAME_URL
unset DB_PASSWORD_URL
unset DATABASE_URL

unset SMTP_SECRET_JSON
unset SMTP_USERNAME
unset SMTP_PASSWORD
unset SMTP_FROM
unset SMTP_TO