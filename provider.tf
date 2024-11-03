terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.74.0"
    }
  }
    backend "s3" {
    bucket         	   = "drupal-tfstate001"
    key              	 = "state/terraform.tfstate"
    region         	   = "us-east-1"
    encrypt        	   = true
  }
}
provider "aws" {
  region = var.aws_region
}
