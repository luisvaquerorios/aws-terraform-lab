resource "aws_vpc" "sportradar_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.instance_name
  }
}

resource "aws_vpc" "admon_vpc" {
  cidr_block           = "10.122.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "admon_vpc"
  }
}

resource "aws_subnet" "my_private_subnet" {
  vpc_id                  = aws_vpc.sportradar_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-private"
  }
}

resource "aws_subnet" "sportradar_subnet" {
  vpc_id                  = aws_vpc.sportradar_vpc.id
  cidr_block              = "10.123.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "sportradar-private"
  }
}

resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.sportradar_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "my_public_rt" {
  vpc_id = aws_vpc.sportradar_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.my_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_internet_gateway.id
}

resource "aws_route_table_association" "my_public_assoc" {
  subnet_id      = aws_subnet.my_private_subnet.id
  route_table_id = aws_route_table.my_public_rt.id
}

resource "aws_security_group" "my_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.sportradar_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["78.30.4.54/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "my_auth" {
  key_name   = "id_ed25519"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_instance" "ec2_dev" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  subnet_id              = aws_subnet.my_private_subnet.id
  key_name               = aws_key_pair.my_auth.id

  root_block_device {
    volume_size = 20
  }
  tags = {
    Name = "Lab-Ubuntu"
  }
}

resource "aws_instance" "ec2_dev_2" {
  instance_type          = "t1.micro"
  ami                    = data.aws_ami.server_ami.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  subnet_id              = aws_subnet.my_private_subnet.id
  key_name               = aws_key_pair.my_auth.id

  root_block_device {
    volume_size = 10
  }
  tags = {
    Name = "Lab-Ubuntu_2"
  }
}
