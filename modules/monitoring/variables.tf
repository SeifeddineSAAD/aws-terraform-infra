variable "name_prefix"      { type = string }
variable "alarm_email"      { type = string }
variable "asg_name"         { type = string }
variable "alb_arn_suffix"   { type = string }
variable "rds_identifier"   { type = string }
variable "cache_cluster_id" { type = string }
variable "tags"             { type = map(string); default = {} }
