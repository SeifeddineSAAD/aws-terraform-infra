################################################################################
# AWS Multi-Tier Infrastructure - Root Module
# Author: [Your Name] | AWS SA Associate | Terraform Associate | PMP
# Description: Production-grade multi-tier AWS infrastructure
################################################################################

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Remote state backend (S3 + DynamoDB locking)
  backend "s3" {
    bucket         = "your-terraform-state-bucket"   # Change this
    key            = "aws-infra/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner_email
    }
  }
}

################################################################################
# Local Values
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

################################################################################
# VPC Module - Network Foundation
################################################################################

module "vpc" {
  source = "./modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.environment == "dev" ? true : false  # Cost optimization for dev

  tags = local.common_tags
}

################################################################################
# ALB Module - Application Load Balancer
################################################################################

module "alb" {
  source = "./modules/alb"

  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  certificate_arn    = var.acm_certificate_arn
  health_check_path  = var.health_check_path

  tags = local.common_tags
}

################################################################################
# EC2 Module - Auto Scaling Group
################################################################################

module "ec2" {
  source = "./modules/ec2"

  name_prefix          = local.name_prefix
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  target_group_arn     = module.alb.target_group_arn

  instance_type    = var.ec2_instance_type
  ami_id           = var.ec2_ami_id
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  # Pass DB and cache endpoints as environment variables to EC2
  db_endpoint    = module.rds.db_endpoint
  cache_endpoint = module.elasticache.redis_endpoint

  tags = local.common_tags
}

################################################################################
# RDS Module - MySQL Database
################################################################################

module "rds" {
  source = "./modules/rds"

  name_prefix           = local.name_prefix
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ec2_security_group_id = module.ec2.security_group_id

  db_name           = var.db_name
  db_username       = var.db_username
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  multi_az          = var.environment == "prod" ? true : false  # Multi-AZ only in prod
  backup_retention  = var.environment == "prod" ? 7 : 1

  tags = local.common_tags
}

################################################################################
# ElastiCache Module - Redis
################################################################################

module "elasticache" {
  source = "./modules/elasticache"

  name_prefix           = local.name_prefix
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ec2_security_group_id = module.ec2.security_group_id

  node_type       = var.cache_node_type
  num_cache_nodes = var.environment == "prod" ? 2 : 1

  tags = local.common_tags
}

################################################################################
# Monitoring Module - CloudWatch + SNS
################################################################################

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix    = local.name_prefix
  alarm_email    = var.alarm_email

  # Resources to monitor
  asg_name       = module.ec2.asg_name
  alb_arn_suffix = module.alb.alb_arn_suffix
  rds_identifier = module.rds.db_identifier
  cache_cluster_id = module.elasticache.cluster_id

  tags = local.common_tags
}
