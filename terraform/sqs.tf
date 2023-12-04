locals {
  queue_name          = "clojars-events"
  age_alarm_threshold = 600
}

resource "aws_sqs_queue" "events_dlq" {
  name = "${local.queue_name}-dlq"

  message_retention_seconds = 1209600 // 14 days
}

resource "aws_sqs_queue" "events" {
  name = local.queue_name

  visibility_timeout_seconds = 60
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.events_dlq.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sns_topic" "alarm_topic" {
  name = "clojars-alarms"
}

resource "aws_sns_topic_subscription" "email_alarm_target" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = "contact@clojars.org"
}

resource "aws_cloudwatch_metric_alarm" "message_age_alarm" {
  alarm_name        = "'${local.queue_name}' queue processing delayed"
  alarm_description = "Oldest message in '${local.queue_name}' is older than ${local.age_alarm_threshold} seconds."

  metric_name = "ApproximateAgeOfOldestMessage"
  namespace   = "AWS/SQS"

  dimensions = {
    QueueName = local.queue_name
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  threshold           = local.age_alarm_threshold

  evaluation_periods  = "5"
  datapoints_to_alarm = "1"
  period              = "60"
  treat_missing_data  = "missing"

  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.alarm_topic.arn]
  ok_actions      = [aws_sns_topic.alarm_topic.arn]
}
