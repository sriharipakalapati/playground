# ##########################################################################################################
# Create S3 Bucket to store Exceptions 
# ##########################################################################################################
module "dev_aws_s3_etl_dynamodb_bucket" {
  source = "modules/s3"
  name   = "a204309-etl-dynamodb-test"
}

output "S3:bucket_name" {
  value = "${module.dev_aws_s3_etl_dynamodb_bucket.id}"
}

output "S3:bucket_arn" {
  value = "${module.dev_aws_s3_etl_dynamodb_bucket.arn}"
}

# ###########################################################################################################
# Create DynamoDB table
# ###########################################################################################################
module "dev_aws_dynamodb_exception_hub_tax_lots" {
  source = "modules/dynamodb"
  tags   = "${var.tags}"
}

output "DynamoDB:arn" {
  value = "${module.dev_aws_dynamodb_exception_hub_tax_lots.arn}"
}

# ###########################################################################################################
# Create Policy to allow access to access to S3 & DynamoDB
# ###########################################################################################################
module "dev_aws_lambda_policy" {
  asset_id         = "${var.asset_id}"
  environment      = "${var.environment}"
  source           = "git::https://git.sami.int.thomsonreuters.com/wm_devops/terraform_module_aws_policy.git"
  name             = "s3_dynamodb_exceptionhub_migration"
  description      = "This policy allows data from the Exception Hub bucket to be transfered to the Exception Hub DynamoDb Table"
  policy_json_file = "./resources/policy_s3_dynamodb_exceptionhub_migration.json"
}

output "dev_aws_lambda_policy:name" {
  value = "${module.dev_aws_lambda_policy.name}"
}

output "dev_aws_lambda_policy:arn" {
  value = "${module.dev_aws_lambda_policy.arn}"
}

# ###########################################################################################################
# Create Role (and attach Policy) to attach to lambda
# ###########################################################################################################
module "dev_aws_role" {
  source         = "git::https://git.sami.int.thomsonreuters.com/wm_devops/terraform_module_aws_role.git"
  name           = "a204309_role_s3_dynamodb_exceptionhub_migration"
  role_json_file = "./resources/role_lambda.json"
}

resource "aws_iam_role_policy_attachment" "role_policy_attach" {
  role       = "${module.dev_aws_role.id}"
  policy_arn = "${module.dev_aws_lambda_policy.arn}"
}

# ###########################################################################################################
# Create Lambda Function to parse csv file in S3 and push it to DynamoDB
# ###########################################################################################################
module "dev_aws_lambda_exceptions_csv_dynamodb" {
  asset_id             = "${var.asset_id}"
  environment          = "${var.environment}"
  resource_owner       = "${var.resource_owner}"
  financial_identifier = "${var.financial_identifier}"
  source               = "git::https://git.sami.int.thomsonreuters.com/wm_devops/terraform_module_aws_lambda.git"
  name                 = "a204309_Dev_Exceptions_Csv_Dynamodb"
  language             = "js"
  zip_file_location    = "./resources/lambda_csv_to_dynamo.zip"
  role                 = "${module.dev_aws_role.arn}"

  environment_variables = {
    "tableName" = "${module.dev_aws_dynamodb_exception_hub_tax_lots.name}"
  }
}

# #############################################
# Allow Bucket to envoke lambda function
# #############################################
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${module.dev_aws_lambda_exceptions_csv_dynamodb.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${module.dev_aws_s3_etl_dynamodb_bucket.arn}"
}

# #############################################
# Allow Lambda to trigger on S3 Object Created
# #############################################
resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
  bucket = "${module.dev_aws_s3_etl_dynamodb_bucket.id}"

  lambda_function {
    lambda_function_arn = "${module.dev_aws_lambda_exceptions_csv_dynamodb.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "exceptions/"
    filter_suffix       = ".csv"
  }
}

# ###########################################################################################################
# Create Lambda Function retrieve data from DynamoDB
# ###########################################################################################################
module "dev_aws_lambda_exceptions_dynamodb" {
  asset_id             = "${var.asset_id}"
  environment          = "${var.environment}"
  resource_owner       = "${var.resource_owner}"
  financial_identifier = "${var.financial_identifier}"
  source               = "git::https://git.sami.int.thomsonreuters.com/wm_devops/terraform_module_aws_lambda.git"
  name                 = "exception_dynamo"
  language             = "js"
  zip_file_location    = "./resources/lambda_dynamodb_exception_access.zip"
  role                 = "${module.dev_aws_role.arn}"

  tags = {
    "this_is_an_extra_tag" = "lambda"
  }

  environment_variables = {
    "tableName" = "${module.dev_aws_dynamodb_exception_hub_tax_lots.name}"
  }
}
