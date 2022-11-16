terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

# 1. Create vpc
resource "aws_vpc" "dev-vpc" {
cidr_block = "172.16.1.0/25"
  tags = {
    Name = "dev"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.dev-vpc.id
}

# # 3. Create Custom Route Table
resource "aws_route_table" "dev-route-table" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Dev"
  }
}

# 4. Create a Public Subnet
resource "aws_subnet" "public-subnet" {
  count = length(var.public_subnets)
  vpc_id            = aws_vpc.dev-vpc.id
  cidr_block = var.public_subnets[count.index]
  availability_zone = var.subnets_availability_zones[count.index]

  tags = {
    Name = "public-${count.index}"
  }
}

# 4.1 Create Private Subnet
resource "aws_subnet" "private-subnet" {
  count = length(var.private_subnets)
  vpc_id            = aws_vpc.dev-vpc.id
  cidr_block = var.private_subnets[count.index]
  availability_zone = var.subnets_availability_zones[count.index]

  tags = {
    Name = "private-${count.index}"
  }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  count = length(var.public_subnets)
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.dev-route-table.id
}

# 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.dev-vpc.cidr_block]
  }

  egress {
    description = "Download from Internet"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  count = length(var.public_subnets)
  subnet_id       = aws_subnet.public-subnet[count.index].id
  security_groups = [aws_security_group.allow_web.id]
}

# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic[0].id
  depends_on                = [aws_internet_gateway.gw, aws_instance.web-server-instance]
}


resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# 9. Create Centos server
resource "aws_instance" "web-server-instance" {
  ami               = "ami-06640050dc3f556bb" # Ubuntu 18.04
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = aws_key_pair.deployer.key_name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic[0].id
  }

    user_data = file("scripts/startup.sh")
  tags = {
    Name = "web-server"
  }
}

# 10. Create Security Group for database
resource "aws_security_group" "allow_db" {
  name        = "allow_db_traffic"
  description = "Allow DB inbound traffic"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description = "db_access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_db"
  }

  depends_on = [
    aws_vpc.dev-vpc
  ]
}

# 11. Create database

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.public-subnet[0].id, aws_subnet.public-subnet[1].id]

  tags = {
    Name = "letscode-db-subnet-group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = var.db_name
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = var.db_user
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.allow_db.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
}

# 12. Create s3 bucket

resource "aws_s3_bucket" "website" {
  bucket = "letscodewebapp"
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.website.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}


output "server_public_ip" {
  value = aws_eip.one.public_ip
}

output "server_id" {
  value = aws_instance.web-server-instance.id
}

output "db_url" {
  value = aws_db_instance.default.address 
}

output "s3_bucket_address" {
  value = aws_s3_bucket.website.website_endpoint
}