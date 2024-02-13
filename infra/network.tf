#--------------------------------------------------------------
# 基本形
#--------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr
  tags       = merge(var.tags, { "Name" = "vpc-fargate-cicd" })
}

resource "aws_subnet" "private_subnet_1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 0) // 10.0.0.0/24
  availability_zone = "ap-northeast-1a"
  tags              = merge(var.tags, { "Name" = "private-subnet-1a" })
}

resource "aws_subnet" "private_subnet_1c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 2) // 10.0.2.0/24
  availability_zone = "ap-northeast-1c"
  tags              = merge(var.tags, { "Name" = "private-subnet-1c" })
}

resource "aws_subnet" "public_subnet_1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1) // 10.0.1.0/24
  availability_zone = "ap-northeast-1a"
  tags              = merge(var.tags, { "Name" = "public-subnet-1a" })
}

resource "aws_subnet" "public_subnet_1c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 3) // 10.0.3.0/24
  availability_zone = "ap-northeast-1c"
  tags              = merge(var.tags, { "Name" = "public-subnet-1c" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { "Name" = "igw-fargate-cicd" })
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { "Name" = "public-route-table" })
}

resource "aws_route_table_association" "public_subnet_1a_association" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_1c_association" {
  subnet_id      = aws_subnet.public_subnet_1c.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}


#--------------------------------------------------------------
# NAT Gateway Route Table
#--------------------------------------------------------------
resource "aws_route_table" "private_route_table_1a" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { "Name" = "private-route-table-1a" })
}

resource "aws_route_table" "private_route_table_1c" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { "Name" = "private-route-table-1c" })
}

resource "aws_route_table_association" "private_subnet_1a_association" {
  route_table_id = aws_route_table.private_route_table_1a.id
  subnet_id = aws_route_table.private_route_table_1a.id
}

resource "aws_route_table_association" "private_subnet_1c_association" {
  route_table_id = aws_route_table.private_route_table_1c.id
  subnet_id = aws_route_table.private_route_table_1c.id
}

resource "aws_route" "private_route_1a" {
  route_table_id         = aws_route_table.private_route_table_1a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ngw1.id
}

resource "aws_route" "private_route_1c" {
  route_table_id         = aws_route_table.private_route_table_1c.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ngw2.id
}

#--------------------------------------------------------------
# Elastic IP (For Nat Gateway)
#--------------------------------------------------------------
resource "aws_eip" "ngw1" {
  vpc  = true
  tags = merge(var.tags, { "Name" = "eip-ngw1" })
}


resource "aws_eip" "ngw2" {
  vpc  = true
  tags = merge(var.tags, { "Name" = "eip-ngw2" })
}

#--------------------------------------------------------------
# NAT Gateway
#--------------------------------------------------------------
resource "aws_nat_gateway" "ngw1" {
  allocation_id = aws_eip.ngw1.id
  subnet_id     = aws_subnet.public_subnet_1a.id
  tags          = merge(var.tags, { "Name" = "ngw1" })

  # NOTE: NATゲートウェイが配置されるVPCにインターネットゲートウェイが関連付けられている必要があります。これは、NATゲートウェイを介してプライベートサブネットからインターネットにアクセスするため
  depends_on = [
    aws_internet_gateway.igw
  ]
}

resource "aws_nat_gateway" "ngw2" {
  allocation_id = aws_eip.ngw2.id
  subnet_id     = aws_subnet.public_subnet_1c.id
  tags          = merge(var.tags, { "Name" = "ngw2" })
  depends_on = [
    aws_internet_gateway.igw
  ]
}

#--------------------------------------------------------------
# Security Group
#--------------------------------------------------------------
resource "aws_security_group" "alb" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { "Name" = "sg-alb" })
}

resource "aws_security_group_rule" "allow_http_ingress" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_app_sg_outbound" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_group_id = aws_security_group.alb.id
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group" "app" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { "Name" = "sg-app" })
}

resource "aws_security_group_rule" "allow_app_ingress" {
  type        = "ingress"
  from_port   = var.container_port
  to_port     = var.container_port
  protocol    = "tcp"
  security_group_id = aws_security_group.app.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "allow_every_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  security_group_id = aws_security_group.app.id
  cidr_blocks = [ "0.0.0.0/0" ]
}
