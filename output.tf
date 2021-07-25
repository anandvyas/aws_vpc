output "vpc_id" {
  description = "The ID of the VPC"
  value       = concat(aws_vpc.vpc.*.id, [""])[0]
}

output "vpc_default_security_group_id" {
  description = "VPC default group ID"
  value       = aws_default_security_group.default.id
}

output "cidr_block" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private.*.id
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = aws_subnet.private.*.cidr_block
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public.*.id
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = aws_subnet.public.*.cidr_block
}

output "environment_bucket" {
  description = "Environment bucket"
  value       = aws_s3_bucket.this.id
}

output "environment_hosted_zone_id" {
  description = "Environment bucket"
  value       = aws_route53_zone.this.zone_id
}

output "environment_kms_key_id" {
  description = "Environment KMS"
  value       = aws_kms_key.this.arn
}
