variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "aws_az" {
  description = ""
  type        = list(any)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR for the VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_private_subnets" {
  description = ""
  type        = list(any)
  default     = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
}

variable "vpc_public_subnets" {
  description = ""
  type        = list(any)
  default     = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
}

variable "vpcflowlogs" {
  type    = bool
  default = false
}

variable "support_dl" {
  type = string
}

variable "infra_dl" {
  type = string
}

variable "additional_tags" {
  default = {}
  description = "Global tags"
  type        = map(string)
}
