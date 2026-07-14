#!/bin/bash

sudo apt update

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
    --collector.systemd.unit-include='(prometheus|grafana-server|node_exporter|docker)\.service'

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

# Install dependencies for PostgreSQL support for Open WebUI
sudo apt install python3-pip python3.12-venv -y
python3 -m venv venv
source venv/bin/activate
# pip install open-webui[all]

# sudo docker run -d -p 3000:8080 -e OLLAMA_BASE_URL="http://${DNS_NAME}" --name open-webui --restart always ghcr.io/open-webui/open-webui:main-slim
