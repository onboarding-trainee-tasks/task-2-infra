#!/bin/bash

set -euo pipefail

sudo cloud-init status --wait

GRAFANA_DATASOURCE_SOURCE="/tmp/datasources.yaml"
GRAFANA_PROVIDER_SOURCE="/tmp/provider.yaml"
GRAFANA_INSTANCES_DASHBOARD_SOURCE="/tmp/instances-dashboard.json"
GRAFANA_SERVICES_DASHBOARD_SOURCE="/tmp/services-dashboard.json"
GRAFANA_AWS_DASHBOARD_SOURCE="/tmp/aws-infra-dashboard.json"
GRAFANA_ALERTS_SOURCE="/tmp/alert-rules.yaml"

PROMETHEUS_RULES_SOURCE="/tmp/service-rules.yml"
ALERTMANAGER_CONFIG_SOURCE="/tmp/alertmanager.yaml"

sudo mkdir -p /etc/grafana/provisioning/datasources
sudo mkdir -p /etc/grafana/provisioning/dashboards
sudo mkdir -p /etc/grafana/provisioning/alerting
sudo mkdir -p /var/lib/grafana/dashboards

sudo mkdir -p /etc/prometheus/rules

### Install Prometheus datasource configuration

sudo install \
    -m 0644 \
    "$GRAFANA_DATASOURCE_SOURCE" \
    /etc/grafana/provisioning/datasources/prometheus.yaml

### Install dashboard provider configuration

sudo install \
    -m 0644 \
    "$GRAFANA_PROVIDER_SOURCE" \
    /etc/grafana/provisioning/dashboards/provider.yaml

### Install infrastructure dashboards

sudo install \
    -o grafana \
    -g grafana \
    -m 0644 \
    "$GRAFANA_INSTANCES_DASHBOARD_SOURCE" \
    /var/lib/grafana/dashboards/instances-dashboard.json

sudo install \
    -o grafana \
    -g grafana \
    -m 0644 \
    "$GRAFANA_SERVICES_DASHBOARD_SOURCE" \
    /var/lib/grafana/dashboards/services-dashboard.json

sudo install \
    -o grafana \
    -g grafana \
    -m 0644 \
    "$GRAFANA_AWS_DASHBOARD_SOURCE" \
    /var/lib/grafana/dashboards/aws-infra-dashboard.json

sudo install \
    -o grafana \
    -g grafana \
    -m 0644 \
    "$GRAFANA_ALERTS_SOURCE" \
    /etc/grafana/provisioning/alerting/alert-rules.yaml

### Install Prometheus rules
sudo install \
    -m 0644 \
    "$PROMETHEUS_RULES_SOURCE" \
    /etc/prometheus/rules/service-rules.yml

### Install AlertManager
sudo install \
    -m 0644 \
    "$ALERTMANAGER_CONFIG_SOURCE" \
    /etc/alertmanager/alertmanager.yaml

### Install AlertManager secrets
sudo install \
  -d \
  -o alertmanager \
  -g alertmanager \
  -m 0750 \
  /etc/alertmanager/secrets

sudo install \
  -o alertmanager \
  -g alertmanager \
  -m 0640 \
  /dev/null \
  /etc/alertmanager/secrets/smtp_password

read -rsp "Gmail App Password: " SMTP_APP_PASSWORD
echo

printf '%s' "$SMTP_APP_PASSWORD" \
  | sudo tee /etc/alertmanager/secrets/smtp_password \
  > /dev/null

unset SMTP_APP_PASSWORD

sudo systemctl enable grafana-server
sudo systemctl restart grafana-server

sudo systemctl enable prometheus
sudo systemctl restart prometheus

sudo systemctl enable alertmanager
sudo systemctl restart alertmanager