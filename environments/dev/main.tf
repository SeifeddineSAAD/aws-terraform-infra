################################################################################
# Dev Environment Entry Point
################################################################################

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = { source = "hashicorp/aws"; version = "~> 5.0" }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

module "infrastructure" {
  source = "../../"

  environment  = "dev"
  project_name = var.project_name
  aws_region   = var.aws_region
  owner_email  = var.owner_email
  alarm_email  = var.alarm_email

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = true

  acm_certificate_arn  = var.acm_certificate_arn
  health_check_path    = var.health_check_path

  ec2_instance_type    = var.ec2_instance_type
  ec2_ami_id           = var.ec2_ami_id
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity

  rds_instance_class    = var.rds_instance_class
  rds_allocated_storage = var.rds_allocated_storage
  db_name               = var.db_name
  db_username           = var.db_username

  cache_node_type = var.cache_node_type
}
