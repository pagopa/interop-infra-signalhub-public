variable "aws_region" {
  type        = string
  description = "AWS region (default is Milan)"
  default     = "eu-south-1"
}

variable "env" {
  type        = string
  description = "Environment name"
  default     = "Uat"
}

variable "tags" {
  type = map(any)
  default = {
    "CreatedBy" : "Terraform",
  }
}
