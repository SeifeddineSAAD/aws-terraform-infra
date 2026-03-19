# 🏗️ AWS Multi-Tier Infrastructure with Terraform

[![Terraform](https://img.shields.io/badge/Terraform-1.7+-7B42BC?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Solutions_Architect-FF9900?logo=amazon-aws)](https://aws.amazon.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI/CD](https://github.com/YOUR_USERNAME/aws-terraform-infra/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/YOUR_USERNAME/aws-terraform-infra/actions)

> **Production-grade AWS multi-tier architecture** deployed with Terraform IaC.  
> Designed and maintained by a **PMP + AWS Solutions Architect Associate + Terraform Associate** certified engineer.

---

## 📐 Architecture Overview

```
                          ┌─────────────────────────────────────────────────────────┐
                          │                    AWS Cloud (eu-west-1)                 │
                          │                                                          │
    Internet              │   ┌──────────────────────────────────────────────────┐  │
       │                  │   │                    VPC (10.0.0.0/16)             │  │
       ▼                  │   │                                                  │  │
  ┌─────────┐             │   │  ┌─────────────────────────────────────────────┐ │  │
  │ Route53 │─────────────┼───┼─▶│          Public Subnets (AZ-a, AZ-b)       │ │  │
  └─────────┘             │   │  │  ┌────────────────────────────────────────┐ │ │  │
       │                  │   │  │  │   Application Load Balancer (ALB)      │ │ │  │
  ┌─────────┐             │   │  │  │         HTTPS (ACM Certificate)        │ │ │  │
  │   ACM   │             │   │  │  └────────────────────┬───────────────────┘ │ │  │
  └─────────┘             │   │  │                       │                     │ │  │
                          │   │  │  ┌────────────────────▼───────────────────┐ │ │  │
                          │   │  │  │   NAT Gateway      │   Bastion Host    │ │ │  │
                          │   │  └──┼────────────────────┼───────────────────┘ │ │  │
                          │   │     │                    │                     │ │  │
                          │   │  ┌──▼────────────────────▼──────────────────┐  │ │  │
                          │   │  │          Private Subnets (AZ-a, AZ-b)    │  │ │  │
                          │   │  │                                           │  │ │  │
                          │   │  │  ┌──────────────────────────────────────┐ │  │ │  │
                          │   │  │  │   EC2 Auto Scaling Group             │ │  │ │  │
                          │   │  │  │   (t3.medium, min:2 max:10)          │ │  │ │  │
                          │   │  │  └────────────────┬─────────────────────┘ │  │ │  │
                          │   │  │                   │                        │  │ │  │
                          │   │  │  ┌────────────────▼──────┐ ┌────────────┐ │  │ │  │
                          │   │  │  │  RDS MySQL Multi-AZ   │ │ ElastiCache│ │  │ │  │
                          │   │  │  │  (db.t3.medium)       │ │ Redis      │ │  │ │  │
                          │   │  │  └───────────────────────┘ └────────────┘ │  │ │  │
                          │   │  └──────────────────────────────────────────┘  │ │  │
                          │   │                                                  │ │  │
                          │   │  ┌──────────────────────────────────────────┐   │ │  │
                          │   │  │    Monitoring & Observability             │   │ │  │
                          │   │  │  CloudWatch Logs │ Alarms │ SNS Alerts   │   │ │  │
                          │   │  └──────────────────────────────────────────┘   │ │  │
                          │   └──────────────────────────────────────────────────┘ │  │
                          │                                                          │  │
                          │  ┌───────────────────────────────────────────────────┐  │  │
                          │  │  State Management: S3 Backend + DynamoDB Locking  │  │  │
                          │  └───────────────────────────────────────────────────┘  │  │
                          └─────────────────────────────────────────────────────────┘  │
                                                                                        │
```

---

## 🚀 Features

| Feature | Implementation |
|---|---|
| **Infrastructure as Code** | Terraform 1.7+ with reusable modules |
| **High Availability** | Multi-AZ deployment (2 AZs minimum) |
| **Auto Scaling** | EC2 ASG with CPU-based scaling policies |
| **Security** | Security Groups, NACLs, private subnets, encrypted storage |
| **Database** | RDS MySQL Multi-AZ with automated backups |
| **Caching** | ElastiCache Redis cluster for session/data caching |
| **Load Balancing** | ALB with HTTPS termination (ACM) |
| **DNS** | Route53 with health checks |
| **Monitoring** | CloudWatch dashboards, alarms, SNS notifications |
| **State Management** | Remote S3 backend + DynamoDB state locking |
| **CI/CD** | GitHub Actions for automated `terraform plan` on PRs |
| **Multi-Environment** | dev / staging / prod workspaces |
| **Cost Optimized** | Auto Scaling, right-sized instances, lifecycle policies |

---

## 📁 Project Structure

```
aws-terraform-infra/
├── modules/                    # Reusable Terraform modules
│   ├── vpc/                    # VPC, subnets, IGW, NAT, route tables
│   ├── alb/                    # Application Load Balancer + HTTPS
│   ├── ec2/                    # Auto Scaling Group + Launch Template
│   ├── rds/                    # RDS MySQL Multi-AZ
│   ├── elasticache/            # ElastiCache Redis
│   └── monitoring/             # CloudWatch + SNS alerts
├── environments/
│   ├── dev/                    # Development environment
│   ├── staging/                # Staging environment
│   └── prod/                   # Production environment
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml  # Auto plan on PRs
│       └── terraform-apply.yml # Auto apply on merge to main
├── backend.tf                  # S3 + DynamoDB remote state
├── main.tf                     # Root module
├── variables.tf                # Input variables
├── outputs.tf                  # Output values
└── README.md
```

---

## ⚡ Quick Start

### Prerequisites

```bash
# Install Terraform
brew install terraform        # macOS
choco install terraform       # Windows
sudo apt install terraform    # Ubuntu

# Configure AWS CLI
aws configure
# AWS Access Key ID: ***
# AWS Region: eu-west-1

# Verify
terraform version  # >= 1.7.0
aws sts get-caller-identity
```

### 1. Bootstrap Remote State (first time only)

```bash
cd bootstrap/
terraform init && terraform apply
```

### 2. Deploy Dev Environment

```bash
cd environments/dev/
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. Deploy to Production

```bash
cd environments/prod/
terraform init
terraform plan -var-file="prod.tfvars" -out=tfplan
# Review plan carefully!
terraform apply tfplan
```

---

## 💰 Estimated Monthly Cost (dev environment)

| Resource | Type | Cost/month |
|---|---|---|
| EC2 (2x t3.medium) | Auto Scaling | ~$60 |
| RDS MySQL (db.t3.medium) | Single-AZ dev | ~$50 |
| ALB | Application LB | ~$20 |
| ElastiCache (cache.t3.micro) | Redis | ~$15 |
| NAT Gateway | 1x AZ | ~$35 |
| Route53 | Hosted Zone | ~$1 |
| CloudWatch | Logs + Alarms | ~$5 |
| **Total (dev)** | | **~$186/month** |

> 💡 **Production** with Multi-AZ RDS + 2x NAT GW ≈ $400-600/month depending on traffic.

---

## 🔐 Security Best Practices Applied

- ✅ No public EC2 instances (only via ALB + Bastion)
- ✅ RDS in private subnet, no public access
- ✅ Encrypted EBS volumes and RDS storage (AES-256)
- ✅ Security Groups follow least-privilege principle
- ✅ Secrets managed via AWS Secrets Manager (not hardcoded)
- ✅ CloudTrail enabled for audit logging
- ✅ HTTPS enforced on ALB (HTTP → HTTPS redirect)

---

## 👤 Author

**[Seifeddine SAAD]**  
AWS Solutions Architect Associate | Terraform Associate | PMP | ITIL  
📧 saad.seif@gmail.com  
🔗 [LinkedIn](http://www.linkedin.com/in/seifeddine-saad) | [GitHub](https://github.com/SeifeddineSAAD)

---

## 📜 License

MIT License — feel free to use this as a template for your own infrastructure.
