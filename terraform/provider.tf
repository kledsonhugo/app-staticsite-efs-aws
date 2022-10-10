# PROVIDER
terraform {

  required_version = "~> 1.3.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.34"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
  }

  backend "s3" {
    bucket         = "tf-state-efs-bucket"
    key            = "terraform.tfstate"
    dynamodb_table = "tf-state-efs-table"
    region         = "us-east-1"
  }

}

provider "aws" {
  region  = "us-east-1"
}