variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"  # Example region
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"  # Example CIDR for the VPC
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"  # Example CIDR for the subnet
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-047126e50991d067b"  # Replace with a valid AMI ID in your chosen region
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"  # Example instance type (eligible for free tier)
}

variable "key_name" {
  description = "Name of the key pair to use for the instance"
  type        = string
  default     = "my_key_01"  # Replace with your actual key pair name
}
