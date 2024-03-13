# --- Configuring and provisioning lambda function --- #
resource "aws_lambda_function" "myfunc" {
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  function_name    = "myfunc"
  role             = aws_iam_role.iam_for_aws_lambda.arn
  handler          = "func.lambda_handler"
  runtime          = "python3.8"
}

resource "aws_iam_role" "iam_for_aws_lambda" {
  name = "iam_for_aws_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_resume_challenge_policy" {

  name        = "aws_iam_policy_for_resume_challenge_policy"
  path        = "/"
  description = "AWS IAM Policy for managing the resume challenge role"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*",
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:UpdateItem",
            "dynamodb:GetItem",
            "dynamodb:PutItem"
          ],
          "Resource" : "arn:aws:dynamodb:*:*:table/cloudresume_views_ddb"
        },
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.iam_for_aws_lambda.name
  policy_arn = aws_iam_policy.iam_policy_for_resume_challenge_policy.arn
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/func.py"
  output_path = "${path.module}/lambda/packedlambda.zip"
}

resource "aws_lambda_function_url" "url1" {
  function_name      = aws_lambda_function.myfunc.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["https://ranikaresume.com"]
    allow_methods     = ["POST"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

# --- Creates DynamoDB Table --- #
resource "aws_dynamodb_table" "cloudresume_views_ddb" {
  name           = "cloudresume_views_ddb"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  lifecycle { ignore_changes = [read_capacity, write_capacity] }
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "Cloud Resume Challenge"
  }
}

resource "aws_dynamodb_table_item" "cloudresume_views_ddb" {
  table_name = aws_dynamodb_table.cloudresume_views_ddb.name
  hash_key   = aws_dynamodb_table.cloudresume_views_ddb.hash_key

  item = <<ITEM
{
  "id": {"S": "0"},
  "views": {"N": "1"}
}
ITEM
}

resource "aws_appautoscaling_target" "cloudresume_views_ddb_read_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "table/cloudresume_views_ddb"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "cloudresume_views_ddb_read_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.cloudresume_views_ddb_read_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.cloudresume_views_ddb_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.cloudresume_views_ddb_read_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.cloudresume_views_ddb_read_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = 70
  }
}

resource "aws_appautoscaling_target" "cloudresume_views_ddb_write_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "table/cloudresume_views_ddb"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "cloudresume_views_ddb_write_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.cloudresume_views_ddb_write_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.cloudresume_views_ddb_write_target.resource_id
  scalable_dimension = aws_appautoscaling_target.cloudresume_views_ddb_write_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.cloudresume_views_ddb_write_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = 70
  }
}
