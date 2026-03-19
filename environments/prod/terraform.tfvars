################################################################################
# Production Environment Configuration
################################################################################

environment  = "prod"
project_name = "myapp"
aws_region   = "eu-west-1"
owner_email  = "your.email@example.com"
alarm_email  = "oncall@example.com"

# Networking
vpc_cidr             = "10.1.0.0/16"
availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]

# ALB
acm_certificate_arn = "arn:aws:acm:eu-west-1:123456789012:certificate/REPLACE-ME"
health_check_path   = "/health"

# EC2 - Production sizing
ec2_instance_type    = "t3.medium"
ec2_ami_id           = "ami-0905a3c97561e0b69"
asg_min_size         = 2
asg_max_size         = 10
asg_desired_capacity = 3

# RDS - Multi-AZ production
rds_instance_class    = "db.t3.medium"
rds_allocated_storage = 100
db_name               = "appdb"
db_username           = "dbadmin"

# ElastiCache - 2 nodes for HA
cache_node_type = "cache.t3.small"
