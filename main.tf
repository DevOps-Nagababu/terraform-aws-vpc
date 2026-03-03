# aws vpc 
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = local.vpc_final_tags
}

# Internet gateway 
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # Associating with VPC

  tags = local.igw_final_tags
}