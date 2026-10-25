
# Onboarding Task 2 - Application and Monitoring Infrastructure

This repository contains the Terraform infrastructure for Onboarding Task 2. EC2 instances use custom AMIs built in the `task-2-packer` repository.

## Implementation Features

- Modular Terraform infrastructure with VPC, public/private/database subnets, NAT Gateway, EC2, ASG, internal ALB and PostgreSQL RDS
- EC2 Key Pair and bastion host with SSH ProxyJump access to private LLM instances
- IAM instance profiles and AWS Secrets Manager integration
- Auto Scaling with CPU-based Target Tracking and ALB health checks
- Open WebUI running as a Docker container
- Prometheus, Grafana, Alertmanager and Node Exporter running as standalone services
- Grafana alerts for CPU, memory and disk usage
- Prometheus alert rules for systemd services
- CloudWatch alarms for ALB, RDS and EC2 status checks
- GitHub Actions for Terraform validation, plan and manual apply through AWS OIDC

Default service URLs use the web server public IP:

- Open WebUI: `http://WEB_PUBLIC_IP:3000`
- Grafana: `http://WEB_PUBLIC_IP:5000`
- Prometheus: `http://WEB_PUBLIC_IP:9090`
- Ollama API: ALB DNS name on port `80`

## External dependencies (things created outside Terraform)

The following items must already exist:

1. **AWS credentials**

   For local execution, configure AWS CLI credentials with permissions to manage the infrastructure.

   GitHub Actions uses AWS OIDC with a dedicated IAM role. Static AWS access keys are not required in GitHub.


2. **S3 bucket for Terraform state**

   - Bucket: `tf-backend-onboarding-task`
   - Region: `eu-central-1`
   - State key: `infra/state`

3. **RDS secret in AWS Secrets Manager**

   It should contain:

   ```json
   {
     "db_username": "...",
     "db_password": "..."
   }
   ```

   Replace the secret ARN in `data.tf`

4. **SMTP secret in Secrets Manager**

   Alertmanager is configured for Gmail SMTP and expects:

   ```json
   {
     "smtp_username": "sender@gmail.com",
     "smtp_password": "gmail-app-password",
     "smtp_from": "sender@gmail.com",
     "smtp_to": "receiver@example.com"
   }
   ```

   Replace the secret ARN in `data.tf`

5. **Packer AMIs**

   Build the bastion, LLM and web AMIs from the `task-2-packer` repository. Put
   the resulting IDs into `packer_bastion_ami`, `packer_llm_ami` and
   `packer_web_server_ami`. AMI IDs are region-specific.

6. **EC2 key pair**

   An AWS EC2 key pair named `terraform-ssh-key` in `eu-central-1`, with its
   private `.pem` file stored locally. Terraform references the key created by AWS.

7. **SNS topic**

   An SNS topic named `task-2-alerts`. The CloudWatch module looks it up instead
   of creating it. Add and confirm an email subscription if notifications are
   required.

The old task 1 S3 SQL bucket is no longer used on this branch since `db_init.sql` is included in the bastion AMI and runs during its first boot.

## GitHub Actions CI/CD

The Terraform workflow supports:

- **Pull requests to `main`:** Terraform formatting and configuration validation without accessing the remote backend.
- **Manual `plan`:** AWS OIDC authentication and Terraform plan using the remote S3 state.
- **Manual `apply`:** Creates and applies a Terraform plan in the same workflow run.

AWS deployment uses the `T2-deploy` GitHub Environment. Merging a pull request does not automatically deploy infrastructure.


## How to run

```bash
git clone https://github.com/onboarding-trainee-tasks/task-2-infra.git
cd task-2-infra

terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
terraform apply
```

Confirm the SNS subscription from the received email.


Open WebUI is accessible publicly on port `3000`. Grafana (`5000`) and Prometheus (`9090`) are restricted to the administrative CIDR configured in `variables.tf`.

SSH access to the bastion host uses the same CIDR. Access to private LLM instances is provided through the bastion host.

The Ollama API is accessible internally through the Application Load Balancer.


After apply, get the bastion IP with `terraform output ssh_command`. The output contains the ssh command with SSH key path.

Find the web public IP and ALB DNS name in the EC2/Load Balancer console. On the
instances, user-data logs are available in `/var/log/cloud-init-output.log`.