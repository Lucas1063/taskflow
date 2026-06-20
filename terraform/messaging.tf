resource "aws_sqs_queue" "events" {
  name = "taskflow-events"
}
 
resource "aws_sns_topic" "notifications" {
  name = "taskflow-notifications"
}
 
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
 
# Empacota o codigo da Lambda em um zip automaticamente
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.mjs"
  output_path = "${path.module}/lambda/taskflow-notifier.zip"
}
 
resource "aws_lambda_function" "notifier" {
  function_name    = "taskflow-notifier"
  role             = data.aws_iam_role.lab.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
 
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.notifications.arn
    }
  }
}
 
# Faz cada mensagem da fila acionar a Lambda
resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.events.arn
  function_name    = aws_lambda_function.notifier.arn
  batch_size       = 5
}
