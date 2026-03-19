variable "name_prefix"           { type = string }
variable "vpc_id"                { type = string }
variable "private_subnet_ids"    { type = list(string) }
variable "ec2_security_group_id" { type = string }
variable "db_name"               { type = string }
variable "db_username"           { type = string; sensitive = true }
variable "instance_class"        { type = string }
variable "allocated_storage"     { type = number }
variable "multi_az"              { type = bool; default = false }
variable "backup_retention"      { type = number; default = 7 }
variable "tags"                  { type = map(string); default = {} }
