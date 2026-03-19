# 🚀 Deployment Guide

Complete step-by-step guide to deploy the AWS Multi-Tier Infrastructure.

---

## Prerequisites Checklist

- [ ] AWS CLI configured (`aws sts get-caller-identity`)
- [ ] Terraform >= 1.7 installed (`terraform version`)
- [ ] Git configured
- [ ] ACM certificate created for your domain in `eu-west-1`
- [ ] Domain in Route53 (or update ACM ARN in tfvars)

---

## Step 1 — Bootstrap Remote State (run once)

```bash
cd bootstrap/
terraform init
terraform apply

# Note the outputs:
# state_bucket_name   = "myapp-terraform-state-XXXX"
# dynamodb_table_name = "terraform-state-lock"
```

Update `main.tf` and all `environments/*/main.tf` with your bucket name.

---

## Step 2 — Update Variables

Edit `environments/dev/terraform.tfvars`:

```hcl
owner_email         = "your@email.com"
alarm_email         = "your@email.com"
acm_certificate_arn = "arn:aws:acm:eu-west-1:ACCOUNT:certificate/YOUR-CERT-ID"
ec2_ami_id          = "ami-XXXXXXXX"   # Get latest Amazon Linux 2023
```

Get the latest Amazon Linux 2023 AMI:
```bash
aws ssm get-parameter \
  --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64" \
  --query "Parameter.Value" \
  --output text \
  --region eu-west-1
```

---

## Step 3 — Deploy Dev

```bash
cd environments/dev/
terraform init
terraform plan -var-file="terraform.tfvars" -out=tfplan
terraform apply tfplan
```

Expected output:
```
Apply complete! Resources: 47 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name              = "myapp-dev-alb-XXXXX.eu-west-1.elb.amazonaws.com"
cloudwatch_dashboard_url  = "https://eu-west-1.console.aws.amazon.com/..."
```

---

## Step 4 — Verify Deployment

```bash
# Test ALB health
curl -I https://your-domain.com/health

# Check ASG instances
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names myapp-dev-asg \
  --query "AutoScalingGroups[0].Instances[*].{ID:InstanceId,State:LifecycleState}"

# Check RDS
aws rds describe-db-instances \
  --db-instance-identifier myapp-dev-mysql \
  --query "DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address}"
```

---

## Step 5 — GitHub Actions Setup

1. In GitHub → Settings → Secrets:
   - `AWS_ROLE_ARN_DEV` — IAM role ARN for dev
   - `AWS_ROLE_ARN_PROD` — IAM role ARN for prod

2. Create OIDC provider in AWS for GitHub Actions:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

3. Push to main branch → CI/CD will auto-deploy to dev!

---

## Destroy Infrastructure (when done testing)

```bash
cd environments/dev/
terraform destroy -var-file="terraform.tfvars"
```

> ⚠️ This destroys all resources including the RDS database!
