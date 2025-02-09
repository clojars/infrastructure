resource "aws_cloudwatch_log_group" "clojars-web" {
  name              = "clojars-web"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_stream" "clojars_ednl" {
  name           = "clojars.ednl"
  log_group_name = aws_cloudwatch_log_group.clojars-web.name
}
