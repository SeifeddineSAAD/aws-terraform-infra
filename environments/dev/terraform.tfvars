################################################################################
# Dev Environment Configuration
################################################################################

environment  = "dev"
project_name = "myapp"
aws_region   = "eu-west-1"
owner_email  = "your.email@example.com"
alarm_email  = "your.email@example.com"

# Networking
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["eu-west-1a", "eu-west-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# ALB
acm_certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/REPLACE-ME"
health_check_path   = "/health"

# EC2
ec2_instance_type    = "t3.small"    # Smaller for dev cost savings
ec2_ami_id           = "ami-0905a3c97561e0b69"  # Amazon Linux 2023 eu-west-1
asg_min_size         = 1
asg_max_size         = 3
asg_desired_capacity = 1

# RDS - smaller for dev
rds_instance_class    = "db.t3.micro"
rds_allocated_storage = 10
db_name               = "appdb_dev"
db_username           = "dbadmin"

# ElastiCache
cache_node_type = "cache.t3.micro"
