/***********
VPC Configuration
************/

# Create the VPC
resource "aws_vpc" "account_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  tags = { Name = "donut-vpc" }
}

# Create the Internet Gateway for public subnet access
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.account_vpc.id
  tags = { Name = "donut-igw" }
}

/***********
Subnets Configuration
************/

# Public Subnet (for web server)
resource "aws_subnet" "donuteast2a_public_sn" {
  vpc_id                   = aws_vpc.account_vpc.id
  cidr_block               = "10.0.0.0/18"
  availability_zone        = "us-east-2a"
  map_public_ip_on_launch = true
  tags = { Name = "donut-public-sn" }
}

# Public Subnet 2 (for web server and load balancer)
resource "aws_subnet" "donuteast2b_public_sn" {
  vpc_id                   = aws_vpc.account_vpc.id
  cidr_block               = "10.0.64.0/18"
  availability_zone        = "us-east-2b"
  map_public_ip_on_launch = true
  tags = { Name = "donut-public-sn2" }
}

# Private Subnet 1 (for database server)
resource "aws_subnet" "donuteast2b_private_sn" {
  vpc_id                   = aws_vpc.account_vpc.id
  cidr_block               = "10.0.128.0/18"
  availability_zone        = "us-east-2b"
  map_public_ip_on_launch = true
  tags = { Name = "donut-private-sn" }
}

# Private Subnet 2 (for additional private resources like RDS)
resource "aws_subnet" "donuteast2a_private_sn" {
  vpc_id                   = aws_vpc.account_vpc.id
  cidr_block               = "10.0.192.0/18"
  availability_zone        = "us-east-2a"
  map_public_ip_on_launch = true
  tags = { Name = "donut-private-sn2" }
}

# Create subnet group for use with the RDS instance
resource "aws_db_subnet_group" "donutdb_subnet_group" {
  name        = "donutdb_subnet_group"
  description = "Subnet group for RDS database"
  subnet_ids = [
    aws_subnet.donuteast2b_private_sn.id,
    aws_subnet.donuteast2a_private_sn.id
  ]
  tags = { Name = "donut-db-subnet-group" }
}

/***********
NACLs Configuration
************/

# Web Server NACL - Controls traffic to and from the web server
# resource "aws_network_acl" "web_server_nacl" {
#   vpc_id = aws_vpc.account_vpc.id
#   tags = { Name = "web-server-nacl" }

#   # Ingress Rules for Web Server
#   ingress {
#     rule_no    = 100
#     protocol   = "tcp"
#     from_port  = 22
#     to_port    = 22
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   ingress {
#     rule_no    = 101
#     protocol   = "tcp"
#     from_port  = 80
#     to_port    = 80
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   ingress {
#     rule_no    = 102
#     protocol   = "tcp"
#     from_port  = 443
#     to_port    = 443
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   # Default Egress for all traffic
#   ingress {
#     rule_no    = 102
#     protocol   = "-1"
#     from_port  = 0
#     to_port    = 0
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   # Egress Rules for Web Server
#   egress {
#     rule_no    = 100
#     protocol   = "tcp"
#     from_port  = 80
#     to_port    = 80
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   egress {
#     rule_no    = 101
#     protocol   = "tcp"
#     from_port  = 443
#     to_port    = 443
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   # Default Egress for all traffic
#   egress {
#     rule_no    = 102
#     protocol   = "-1"
#     from_port  = 0
#     to_port    = 0
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }
# }

# # Database Server NACL - Controls traffic to and from the database server
# resource "aws_network_acl" "database_nacl" {
#   vpc_id = aws_vpc.account_vpc.id
#   tags = { Name = "database-nacl" }

#   # Ingress Rules for Database Server
#   ingress {
#     rule_no    = 100
#     protocol   = "tcp"
#     from_port  = 22
#     to_port    = 22
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   ingress {
#     rule_no    = 101
#     protocol   = "tcp"
#     from_port  = 3306  # MySQL default port, adjust as needed
#     to_port    = 3306
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   # Default Egress for all traffic
#   ingress {
#     rule_no    = 102
#     protocol   = "-1"
#     from_port  = 0
#     to_port    = 0
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   # Egress Rules for Database Server
#   egress {
#     rule_no    = 100
#     protocol   = "tcp"
#     from_port  = 80
#     to_port    = 80
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   egress {
#     rule_no    = 101
#     protocol   = "tcp"
#     from_port  = 443
#     to_port    = 443
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }

#   # Default Egress for all traffic
#   egress {
#     rule_no    = 102
#     protocol   = "-1"
#     from_port  = 0
#     to_port    = 0
#     cidr_block = "0.0.0.0/0"
#     action     = "allow"
#   }
# }

# /***********
# NACL Associations
# ************/

# # Associating NACLs to subnets
# resource "aws_network_acl_association" "web_server_nacl_association" {
#   subnet_id      = aws_subnet.donuteast2a_public_sn.id
#   network_acl_id = aws_network_acl.web_server_nacl.id
# }

# resource "aws_network_acl_association" "db_server_nacl_association" {
#   subnet_id      = aws_subnet.donuteast2b_private_sn.id
#   network_acl_id = aws_network_acl.database_nacl.id
# }

# resource "aws_network_acl_association" "db_server_nacl_association2" {
#   subnet_id      = aws_subnet.donuteast2a_private_sn.id
#   network_acl_id = aws_network_acl.database_nacl.id
# }

/***********
NAT Gateway Configuration
************/

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Create the NAT Gateway to provide internet access to private subnets
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.donuteast2b_private_sn.id
  tags = { Name = "donut-nat-gateway" }
}

# Private Route Table Update - Route traffic through the NAT Gateway
#resource "aws_route" "nat_gateway_route" {
#  route_table_id         = aws_route_table.private_route_table.id
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
#}

/***********
Route Tables Configuration
************/

# Public Route Table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.account_vpc.id
  tags = { Name = "donut-public-route-table" }
}

# Private Route Table for private subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.account_vpc.id
  tags = { Name = "donut-private-route-table" }
}

# Create a route for the public route table to allow outbound internet access
resource "aws_route" "internet_route" {
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.internet_gateway.id
}

resource "aws_route" "private_internet_route" {
  route_table_id            = aws_route_table.private_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.internet_gateway.id
}

# Create subnet route table associations
resource "aws_route_table_association" "public_route_table_association_1" {
  subnet_id         = aws_subnet.donuteast2a_public_sn.id
  route_table_id    = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_1" {
  subnet_id         = aws_subnet.donuteast2b_private_sn.id
  route_table_id    = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_2" {
  subnet_id         = aws_subnet.donuteast2a_private_sn.id
  route_table_id    = aws_route_table.public_route_table.id
}

/***********
Security Groups Configuration
************/

# Create Web Security Group (allow SSH, HTTP, and HTTPS)
resource "aws_security_group" "web_security_group" {
  name        = "Web security group"
  description = "Security group that allows 443, 80, and 22"
  vpc_id      = aws_vpc.account_vpc.id
  tags = { Name = "web-security-group" }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Database Security Group (allow access only from web servers)
resource "aws_security_group" "db_security_group" {
  name        = "DB security group"
  description = "DB security group that allows access from web servers"
  vpc_id      = aws_vpc.account_vpc.id
  tags = { Name = "db-security-group" }

  ingress {
    from_port   = 3306  # MySQL default port, adjust as needed
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.web_security_group.id]  # Only allow traffic from the web server
  }

    ingress {
    from_port   = 3306  # MySQL default port, adjust as needed
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}