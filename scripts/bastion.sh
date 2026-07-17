#!/bin/bash

AWS_REGION="${AWS_REGION}"
DB_SECRET_ARN="${DB_SECRET_ARN}"

DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"

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
    --collector.systemd.unit-include='(node_exporter)\.service'

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/node_exporter.service

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

### Setup Database

sudo apt install postgresql-client -y
sudo apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sleep 5
aws s3 cp s3://init-sql-script/db_init.sql /home/ubuntu/db_init.sql
sleep 5

DB_SECRET_JSON=$(aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$DB_SECRET_ARN" \
  --query SecretString \
  --output text)

DB_USERNAME=$(echo "$DB_SECRET_JSON" | jq -r '.db_username')
DB_PASSWORD=$(echo "$DB_SECRET_JSON" | jq -r '.db_password')

PGPASSWORD="$DB_PASSWORD" psql \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --username="$DB_USERNAME" \
  --dbname="$DB_NAME" \
  --file=/home/ubuntu/db_init.sql

unset DB_SECRET_JSON
unset DB_USERNAME
unset DB_PASSWORD

