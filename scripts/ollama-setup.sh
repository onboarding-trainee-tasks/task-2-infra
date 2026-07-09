#!/bin/bash

export HOME='/home/ubuntu'

# APT update and upgrade
sudo apt update
sudo apt upgrade -y

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Update a systemd service for Ollama
echo '[Service]' >> /etc/systemd/system/ollama.service
echo 'Environment="OLLAMA_HOST=0.0.0.0"' >> /etc/systemd/system/ollama.service
echo 'Environment="HOME=/usr/share/ollama"' >> /etc/systemd/system/ollama.service
echo 'Environment="OLLAMA_MODELS=/usr/share/ollama/.ollama/models"' >> /etc/systemd/system/ollama.service


# Reload systemd and restart Ollama service
sudo systemctl daemon-reload
sudo systemctl restart ollama
sudo systemctl enable ollama

sleep 10

# Pull the tinyllama model
ollama pull tinyllama
ollama run tinyllama


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
ExecStart=/usr/local/bin/node_exporter

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/node_exporter.service

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
# ./node_exporter &