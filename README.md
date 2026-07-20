# Onboarding task 2 - application and monitoring infrastructure

This branch is in working pre-packer state. 

Since there is no Packer, all configuration files is needed to provision manually. Steps to provision:
    
1. Send configuration files via SCP:
```bash
scp `
  -o "ProxyCommand=ssh -o IdentitiesOnly=yes -i C:/Onboarding/.ssh/terraform-ssh-key.pem -W %h:%p ubuntu@BASTION_IP" `
  -o IdentitiesOnly=yes `
  -i C:/Onboarding/.ssh/terraform-ssh-key.pem `
  monitoring/grafana/datasources.yaml `
  monitoring/grafana/provider.yaml `
  monitoring/grafana/instances-dashboard.json `
  monitoring/grafana/services-dashboard.json `
  monitoring/grafana/aws-infra-dashboard.json `
  monitoring/grafana/grafana_provisioning.sh `
  monitoring/Grafana/alert-rules.yaml `
  monitoring/prometheus/rules/service-rules.yml `
  ubuntu@WEB_SERVER_IP:/tmp/
```

2. Connect to web server using ProxyJump via bastion host:

```bash
ssh -o ProxyCommand="ssh -i C:\\Onboarding\\.ssh\\terraform-ssh-key.pem -W %h:%p ubuntu@BASTION_IP" -i C:\\Onboarding\\.ssh\\terraform-ssh-key.pem ubuntu@WEB_SERVER_IP
```

3. Run `grafana-provisioning.sh`:
```bash
cd /tmp
bash grafana-provisioning.sh
```

4. Check that Grafana (port 5000), Prometheus (port 9090) and Open Web UI (port 3000) are working.