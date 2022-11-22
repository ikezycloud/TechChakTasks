provider "aws" {
  region = "eu-west-2"
}

#main VPC
#Create a vpc
resource "aws_vpc" "diverso_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "diverso_dev1"
  }
}

#Create a public subnet
resource "aws_subnet" "diverso_Public_subnet" {
  vpc_id                  = aws_vpc.diverso_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2a"

  tags = {
    "Name" = "diverso_dev1_public"
  }
}

#Create a private subnet
resource "aws_subnet" "diverso_Private_subnet" {
  vpc_id     = aws_vpc.diverso_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "diverso_dev1_private"
  }
}

#Create an internet gateway
resource "aws_internet_gateway" "diverso_internet_gateway" {
  vpc_id = aws_vpc.diverso_vpc.id

  tags = {
    "Name" = "diverso_dev1_igw"
  }
}

#Create a public route table
resource "aws_route_table" "diverso_Public_rt" {
  vpc_id = aws_vpc.diverso_vpc.id

  tags = {
    "Name" = "diverso_dev1_public_rt"
  }
}

#Create route 
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.diverso_Public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.diverso_internet_gateway.id
}

#Create route table association
resource "aws_route_table_association" "diverso_Public_assoc" {
  subnet_id      = aws_subnet.diverso_Public_subnet.id
  route_table_id = aws_route_table.diverso_Public_rt.id
}

#Create security group
resource "aws_security_group" "diverso_sg" {
  name        = "diver_sg"
  description = "diverso_security_group"
  vpc_id      = aws_vpc.diverso_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create keypair (terraform)
#resource "aws_key_pair" "diverso_key" {
  #key_name   = "diverso_key"
  #public_key = tls_private_key.rsa.public_key_openssh
#}

#resource "tls_private_key" "rsa" {
  #algorithm = "RSA"
  #rsa_bits  = 4096
#}

#resource "local_file" "diverso_key" {
  #content  = tls_private_key.rsa.private_key_pem
  #filename = "diversokey"
#}

#Create EC2 instance
resource "aws_instance" "diverso1_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  #key_name               = aws_key_pair.diverso_key.id
  vpc_security_group_ids = ["${aws_security_group.diverso_sg.id}"]
  subnet_id              = aws_subnet.diverso_Public_subnet.id
  key_name               = "main-key"
  user_data              = file("userData.sh")

  root_block_device {
    volume_size = 10
  }

  tags = {
    "Name" = "diverso_dev1_node"
  }
}

#Create network interface
resource "aws_network_interface" "diverso_nic" {
  subnet_id       = aws_subnet.diverso_Public_subnet.id
  private_ips     = ["10.0.0.40"]
  security_groups = [aws_security_group.diverso_sg.id]

  attachment {
    instance     = aws_instance.diverso1_node.id
    device_index = 1
  }
}

#create public elastic ip (single eip to a single instance)
resource "aws_eip" "diverso_eip" {
  instance = aws_instance.diverso1_node.id
  vpc      = true
}