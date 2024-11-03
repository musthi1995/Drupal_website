terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.74.0"
    }
  }
    backend "s3" {
    bucket         	   = "drupal-tfstate"
    key              	 = "state/terraform.tfstate"
    region         	   = "ap-southeast-1"
    encrypt        	   = true
  }
}
provider "aws" {
  region = var.aws_region
}
