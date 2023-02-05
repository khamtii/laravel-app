provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "Project_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "project_vpc"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "Project_internet_gateway" {
  vpc_id = aws_vpc.Project_vpc.id
  tags = {
    Name = "Project_internet_gateway"
  }
}


# public route table
resource "aws_route_table" "Project-public-rt" {
  vpc_id = aws_vpc.Project_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Project_internet_gateway.id
  }
  tags = {
    Name = "Project-public-rt"
  }
}

# Associating public subnet 1 with public route table
resource "aws_route_table_association" "Project-public-subnet1-association" {
  subnet_id      = aws_subnet.Project-public-subnet1.id
  route_table_id = aws_route_table.Project-public-rt.id
}

# Associating public subnet 2 with public route table
resource "aws_route_table_association" "Project-public-subnet2-association" {
  subnet_id      = aws_subnet.Project-public-subnet2.id
  route_table_id = aws_route_table.Project-public-rt.id

}

resource "aws_subnet" "Project-public-subnet1" {
  vpc_id                  = aws_vpc.Project_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Project-public-subnet1"
  }
}
# Create Public Subnet-2
resource "aws_subnet" "Project-public-subnet2" {
  vpc_id                  = aws_vpc.Project_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "Project-public-subnet2"
  }
}

resource "aws_network_acl" "Project-network_acl" {
  vpc_id     = aws_vpc.Project_vpc.id
  subnet_ids = [aws_subnet.Project-public-subnet1.id, aws_subnet.Project-public-subnet2.id]

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# Security group for the load balancer
resource "aws_security_group" "Project-load_balancer_sg" {
  name        = "Project-load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.Project_vpc.id
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
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Creating a security group to allow ssh,http and https
resource "aws_security_group" "Project-security-grp-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.Project_vpc.id
  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.Project-load_balancer_sg.id]
  }
  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.Project-load_balancer_sg.id]
  }
  ingress {
    description = "SSH"
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
  tags = {
    Name = "Project-security-grp-rule"
  }
}


# Creating the instances
resource "aws_instance" "Project-server1" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "aws"
  security_groups   = [aws_security_group.Project-security-grp-rule.id]
  subnet_id         = aws_subnet.Project-public-subnet1.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Server-1"
    source = "terraform"
  }
}
# creating instance 2
resource "aws_instance" "Project-server2" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "aws"
  security_groups   = [aws_security_group.Project-security-grp-rule.id]
  subnet_id         = aws_subnet.Project-public-subnet2.id
  availability_zone = "us-east-1b"
  tags = {
    Name   = "Server-2"
    source = "terraform"
  }
}
# creating instance 3
resource "aws_instance" "Project-server3" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "aws"
  security_groups   = [aws_security_group.Project-security-grp-rule.id]
  subnet_id         = aws_subnet.Project-public-subnet1.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Server-3"
    source = "terraform"
  }
}

# Creating host-inventory file to store ip address of instances 
resource "local_file" "Ip_address" {
  filename = "vagrant/mini-project/host-inventory"
  content  = <<EOT
${aws_instance.Project-server1.public_ip}
${aws_instance.Project-server2.public_ip}
${aws_instance.Project-server3.public_ip}
  EOT
}


# Creating project load balancer
resource "aws_lb" "Project-lb" {
  name               = "Project-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Project-load_balancer_sg.id]
  subnets            = [aws_subnet.Project-public-subnet1.id, aws_subnet.Project-public-subnet2.id]
  #enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  depends_on                 = [aws_instance.Project-server1, aws_instance.Project-server2, aws_instance.Project-server3]
}

# Creating target group for the lb
resource "aws_lb_target_group" "Project-target-group" {
  name        = "Project-target-group"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.Project_vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# Creating a listner
resource "aws_lb_listener" "Project-listener" {
  load_balancer_arn = aws_lb.Project-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Project-target-group.arn
  }
}
# Create the listener rule
resource "aws_lb_listener_rule" "Project-listener-rule" {
  listener_arn = aws_lb_listener.Project-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Project-target-group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# Attach target groups to instances
resource "aws_lb_target_group_attachment" "Project-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.Project-target-group.arn
  target_id        = aws_instance.Project-server1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "Project-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.Project-target-group.arn
  target_id        = aws_instance.Project-server2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "Project-target-group-attachment3" {
  target_group_arn = aws_lb_target_group.Project-target-group.arn
  target_id        = aws_instance.Project-server3.id
  port             = 80

}

