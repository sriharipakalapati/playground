# provider "template" {
#   version = "~> 2.0"
# }

provider "aws" {
  version = "~> 1.58.0"
  region  = "us-east-1"
}

# provider "local" {
#   version = "~> 1.1"
# }

# provider "null" {
#   version = "~> 1.0"
# }

terraform {
  required_version = ">= 0.11.11"

  backend "s3" {
    bucket = "a204309-terraform-states"
    key    = "a204309-terraform-test.tfstate"
    region = "us-east-1"
  }
}

variable "asset_id" {
  description = "Asset Insight Id"
  default     = "204309"
}

variable "environment" {
  description = "Environment"
  default     = "dev"
}

variable "financial_identifier" {
  description = "Financial Identifier"
  default     = "283711002"
}

variable "resource_owner" {
  description = "Resource Owner"
  default     = "Management-AWS-ArchitectureTeam@xxx.com"
}

variable "tags" {
  type = "map"

  default = {
    "tr:environment-type"             = "dev"
    "tr:application-asset-insight-id" = "204309"
    "tr:financial-identifier"         = "283711002"
    "tr:resource-owner"               = "Management-AWS-ArchitectureTeam@xxx.com"
  }
}
