data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_secretsmanager_secret" "rds_secrets" {
  arn = "arn:aws:secretsmanager:eu-central-1:583955898731:secret:Task-1-RDS-Secrets-JXWRuA"
}

data "aws_secretsmanager_secret_version" "rds_secrets_version" {
  secret_id = data.aws_secretsmanager_secret.rds_secrets.id
}

variable "allowed_cidr_blocks" {
  description = "A list of allowed CIDR blocks for the security group"
  type        = list(string)
  default     = ["178.212.0.0/16", "146.120.0.0/16", "31.42.0.0/16"]
}

variable "aws_region" {
  description = "Region where resources are deployed"
  type        = string
  default     = "eu-central-1"
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for EC2 instances"
  type        = string
  default     = "terraform-ssh-key"
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket to allow access to"
  type        = string
  default     = "arn:aws:s3:::init-sql-script"
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
  default     = "postgres"
}

variable "min_instance_count" {
  description = "The minimum number of instances for the Auto Scaling group"
  type        = number
  default     = 1
}

variable "max_instance_count" {
  description = "The maximum number of instances for the Auto Scaling group"
  type        = number
  default     = 3
}

variable "desired_instance_count" {
  description = "The desired number of instances for the Auto Scaling group"
  type        = number
  default     = 1
}

variable "rds_instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "The allocated storage for the RDS instance in GB"
  type        = number
  default     = 5
}

variable "autoscaling_policy_value" {
  description = "Target value for the metric"
  type = number
  default = 80
}

variable "sns_topic_name" {
  description = "Name of the SNS Topic for CloudWatch"
  type = string
  default = "task-2-alerts"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "llm"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}