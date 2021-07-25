data "aws_region" "current" {}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block                       = var.vpc_cidr_block
  instance_tenancy                 = "default"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  assign_generated_ipv6_cidr_block = false

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-vpc"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-vpc-default-sg"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

resource "aws_eip" "eip" {
  count = length(var.vpc_private_subnets)
  vpc   = true
  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-elastic-ip-${count.index + 1}"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

#Adding NAT Gateway
resource "aws_nat_gateway" "natgw" {
  count         = length(var.vpc_public_subnets)
  allocation_id = element(aws_eip.eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-nat-gateway-${count.index + 1}"
  })
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Subnets : Private
resource "aws_subnet" "private" {
  count             = length(var.vpc_private_subnets)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.vpc_private_subnets, count.index)
  availability_zone = element(var.aws_az, count.index)
  tags = merge(var.additional_tags, {
    Name                                                                        = "${var.region}-${var.project}-${var.env}-subnet-private-${count.index + 1}"
    "kubernetes.io/cluster/${var.region}-${var.project}-${var.env}-eks-cluster" = "shared"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Route table Private
resource "aws_route_table" "private" {
  count  = length(var.vpc_private_subnets)
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.natgw.*.id, count.index)
  }

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-private-routetable-${count.index + 1}"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Route table Association - Private
resource "aws_route_table_association" "private" {
  count          = length(var.vpc_private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}


# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-igw"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Subnets : Public
resource "aws_subnet" "public" {
  count             = length(var.vpc_public_subnets)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.vpc_public_subnets, count.index)
  availability_zone = element(var.aws_az, count.index)

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-subnet-public-${count.index + 1}"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Route table Public: attach Internet Gateway 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-public-routetable"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Route table Association - public
resource "aws_route_table_association" "public" {
  count          = length(var.vpc_public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}

#Adding aws vpc endpoint s3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-s3-endpoint"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Default ebs encryption globally
resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}

# Environment KMS
resource "aws_kms_key" "this" {
  description             = "kms key for ${var.region}-${var.project}-${var.env}"
  deletion_window_in_days = 10

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-kms"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Create Alias for KMS
resource "aws_kms_alias" "this" {
  name          = "alias/${var.region}-${var.project}-${var.env}-kms"
  target_key_id = aws_kms_key.this.key_id
}

# Environment bucket store VPC flow logs
resource "aws_s3_bucket" "this" {
  bucket = "${var.region}-${var.project}-${var.env}-environment-bucket"
  acl    = "log-delivery-write"

  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-environment-bucket"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_flow_log" "this" {
  count                = var.vpcflowlogs ? 1 : 0
  log_destination      = aws_s3_bucket.this.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-vpc-flowlog"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# environment SNS topic for Infra alerts 
resource "aws_sns_topic" "infra" {
  name = "${var.region}-${var.project}-${var.env}-infra-sns-topic"

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-infra-sns-topic"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# infra temm topic subscription
resource "aws_sns_topic_subscription" "infra" {
  topic_arn              = aws_sns_topic.infra.arn
  protocol               = "email"
  endpoint_auto_confirms = true
  endpoint               = var.infra_dl
}

# environment SNS topic for Support alerts
resource "aws_sns_topic" "support" {
  name = "${var.region}-${var.project}-${var.env}-support-sns-topic"

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-support-sns-topic"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# infra temm topic subscription
resource "aws_sns_topic_subscription" "support" {
  topic_arn              = aws_sns_topic.support.arn
  protocol               = "email"
  endpoint_auto_confirms = true
  endpoint               = var.support_dl
}

# route53 private hosted zone for internal communication
resource "aws_route53_zone" "this" {
  name = "${var.region}-${var.project}-${var.env}-internal.com"

  tags = merge(var.additional_tags, {
    Name = "${var.region}-${var.project}-${var.env}-route53"
  })

  vpc {
    vpc_id = aws_vpc.vpc.id
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}
