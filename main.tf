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

# public subnet creating
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    # roboshop-dev-public-us-east-1a
    {
        Name = "${var.project}-${var.environment}-public-${local.az_names[count.index]}"
    },
    var.public_subnet_tags
  )
}

# private subnet creating
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr[count.index]
  availability_zone = local.az_names[count.index]
  
  tags = merge(
    local.common_tags,
    # roboshop-dev-public-us-east-1a
    {
        Name = "${var.project}-${var.environment}-private-${local.az_names[count.index]}"
    },
    var.private_subnet_tags
  )
}

# database subnet creating
resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidr[count.index]
  availability_zone = local.az_names[count.index]
 
  tags = merge(
    local.common_tags,
    # roboshop-dev-public-us-east-1a
    {
        Name = "${var.project}-${var.environment}-database-${local.az_names[count.index]}"
    },
    var.database_subnet_tags
  )
}

# Route table public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    # roboshop-dev-public
    {
        Name = "${var.project}-${var.environment}-public"
    },
    var.public_route_table_tags
  )
}

# Route table private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    # roboshop-dev-private
    {
        Name = "${var.project}-${var.environment}-private"
    },
    var.private_route_table_tags
  )
}

# Route table database
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    # roboshop-dev-database
    {
        Name = "${var.project}-${var.environment}-database"
    },
    var.database_route_table_tags
  )
}

# aws Route public
resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

# Elastic IP
resource "aws_eip" "nat" {
  domain                    = "vpc"
   tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-nat"
    },
    var.eip_tags
  )
}
# NAT gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    },
    var.nat_gateway_tags
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

# aws Route private
resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}

# aws Route database
resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}
# aws public subnet association with route table
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# aws private subnet association with route table
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# aws database subnet association with route table
resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidr)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}



