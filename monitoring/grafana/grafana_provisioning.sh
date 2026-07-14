#!/bin/bash

set -euo pipefail

sudo cloud-init status --wait

GRAFANA_DATASOURCE_SOURCE="/tmp/datasources.yaml"
GRAFANA_PROVIDER_SOURCE="/tmp/provider.yaml"
GRAFANA_INSTANCES_DASHBOARD_SOURCE="/tmp/instances-dashboard.json"
GRAFANA_SERVICES_DASHBOARD_SOURCE="/tmp/services-dashboard.json"

sudo mkdir -p /etc/grafana/provisioning/datasources
sudo mkdir -p /etc/grafana/provisioning/dashboards
sudo mkdir -p /var/lib/grafana/dashboards

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

### Install infrastructure dashboard

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

sudo systemctl enable grafana-server
sudo systemctl restart grafana-server