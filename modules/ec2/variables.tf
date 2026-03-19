variable "name_prefix"           { type = string }
variable "vpc_id"                { type = string }
variable "private_subnet_ids"    { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "target_group_arn"      { type = string }
variable "instance_type"         { type = string }
variable "ami_id"                { type = string }
variable "min_size"              { type = number }
variable "max_size"              { type = number }
variable "desired_capacity"      { type = number }
variable "db_endpoint"           { type = string }
variable "cache_endpoint"        { type = string }
variable "tags"                  { type = map(string); default = {} }
