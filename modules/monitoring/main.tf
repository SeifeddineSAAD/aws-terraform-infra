################################################################################
# Module: Monitoring
# CloudWatch Dashboard + Alarms + SNS notifications
################################################################################

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

################################################################################
# SNS Topic for Alerts
################################################################################

resource "aws_sns_topic" "alerts" {
  name              = "${var.name_prefix}-alerts"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

################################################################################
# CloudWatch Alarms - ALB
################################################################################

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_description = "ALB 5XX errors exceeded 10 in 2 minutes"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${var.name_prefix}-alb-response-time"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p95"
  threshold           = 2

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_description = "ALB p95 response time > 2s for 3 minutes"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  tags              = var.tags
}

################################################################################
# CloudWatch Alarms - RDS
################################################################################

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_description = "RDS CPU utilization > 80%"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.name_prefix}-rds-low-storage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120  # 5 GB in bytes

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_description = "RDS free storage < 5GB"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.name_prefix}-rds-connections-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 150

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_description = "RDS connections > 150"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  tags              = var.tags
}

################################################################################
# CloudWatch Alarms - ElastiCache
################################################################################

resource "aws_cloudwatch_metric_alarm" "cache_cpu" {
  alarm_name          = "${var.name_prefix}-cache-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 120
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    CacheClusterId = var.cache_cluster_id
  }

  alarm_description = "ElastiCache CPU > 80%"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cache_memory" {
  alarm_name          = "${var.name_prefix}-cache-memory-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 120
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    CacheClusterId = var.cache_cluster_id
  }

  alarm_description = "ElastiCache memory usage > 80%"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  tags              = var.tags
}

################################################################################
# CloudWatch Dashboard
################################################################################

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-overview"

  dashboard_body = jsonencode({
    widgets = [
      # Title
      {
        type   = "text"
        x      = 0; y = 0; width = 24; height = 1
        properties = {
          markdown = "# ${var.name_prefix} Infrastructure Dashboard"
        }
      },
      # ALB Request Count
      {
        type   = "metric"
        x      = 0; y = 1; width = 8; height = 6
        properties = {
          title  = "ALB - Request Count"
          period = 60
          stat   = "Sum"
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]]
          view   = "timeSeries"
        }
      },
      # ALB Response Time
      {
        type   = "metric"
        x      = 8; y = 1; width = 8; height = 6
        properties = {
          title  = "ALB - Response Time (p95)"
          period = 60
          stat   = "p95"
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]]
          view   = "timeSeries"
        }
      },
      # ALB 5XX Errors
      {
        type   = "metric"
        x      = 16; y = 1; width = 8; height = 6
        properties = {
          title  = "ALB - HTTP 5XX Errors"
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
          view   = "timeSeries"
        }
      },
      # ASG Instance Count
      {
        type   = "metric"
        x      = 0; y = 7; width = 8; height = 6
        properties = {
          title  = "ASG - Instance Count"
          period = 60
          stat   = "Average"
          metrics = [["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name]]
          view   = "timeSeries"
        }
      },
      # RDS CPU
      {
        type   = "metric"
        x      = 8; y = 7; width = 8; height = 6
        properties = {
          title  = "RDS - CPU & Connections"
          period = 60
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_identifier, { stat = "Average", label = "CPU %" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_identifier, { stat = "Average", label = "Connections", yAxis = "right" }]
          ]
          view   = "timeSeries"
        }
      },
      # ElastiCache
      {
        type   = "metric"
        x      = 16; y = 7; width = 8; height = 6
        properties = {
          title  = "ElastiCache - Cache Hit Rate"
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/ElastiCache", "CacheHits", "CacheClusterId", var.cache_cluster_id],
            ["AWS/ElastiCache", "CacheMisses", "CacheClusterId", var.cache_cluster_id]
          ]
          view   = "timeSeries"
        }
      }
    ]
  })
}

################################################################################
# CloudWatch Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.name_prefix}/app"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/instance/${var.name_prefix}-mysql/slowquery"
  retention_in_days = 14
  tags              = var.tags
}
