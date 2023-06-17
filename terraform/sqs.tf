resource "aws_sqs_queue" "events_dlq" {
  name = "clojars-events-dlq"

  message_retention_seconds = 1209600 // 14 days
}

resource "aws_sqs_queue" "events" {
  name = "clojars-events"

  visibility_timeout_seconds = 60
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.events_dlq.arn
    maxReceiveCount     = 4
  })
}
