##################
# Backend bucket #
##################

resource "aws_s3_bucket" "s3-backend" {
    bucket = "backend-for-terraform-project1"
}

##################
#    vpc&more    #
##################

module "main-vpc" {
  source = "./modules/VPC-mod"
  main-vpc-cidr = "10.0.0.0/16"
  main-vpc-name = "main-vpc"
}

#Internet gateway
resource "aws_internet_gateway" "main-IGW" {
  vpc_id = module.main-vpc.vpc-id
  tags = {
    Name = "main-IGW"
  }
}

#EIP
resource "aws_eip" "nat-ip" {
  domain = "vpc"
}

#Nat gateway
resource "aws_nat_gateway" "main-NatGW" {
  allocation_id = aws_eip.nat-ip.id
  subnet_id = module.public_subnet_1.public-id
  depends_on = [ aws_eip.nat-ip ]
}

##################
# public subnet  #
##################

module "public_subnet_1" {
  source = "./modules/pub-subnet-mod"
  vpc-id = module.main-vpc.vpc-id
  pub-sub-cidr = "10.0.1.0/24"
  pub-sub-name = "public-subnet-1"
  pub-sub-az = "us-east-1a"
}

module "public_subnet_2" {
  source = "./modules/pub-subnet-mod"
  vpc-id = module.main-vpc.vpc-id
  pub-sub-cidr = "10.0.2.0/24"
  pub-sub-name = "public-subnet-2"
  pub-sub-az = "us-east-1b"
}

##################
# private subnet #
##################

module "private_subnet_1" {
  source = "./modules/prv-subnet-mod"
  vpc-id = module.main-vpc.vpc-id
  prv-sub-cidr = "10.0.3.0/24"
  prv-sub-name = "private-subnet-1"
  prv-sub-az = "us-east-1a"
  depends_on = [ aws_nat_gateway.main-NatGW ]
}

module "private_subnet_2" {
  source = "./modules/prv-subnet-mod"
  vpc-id = module.main-vpc.vpc-id
  prv-sub-cidr = "10.0.4.0/24"
  prv-sub-name = "private-subnet-2"
  prv-sub-az = "us-east-1b"
  depends_on = [ aws_nat_gateway.main-NatGW ]

}

##################
#  route tables  #
##################

module "private-rt" {
  source = "./modules/private-rt-mod"
  rt-name = "private-rt"
  route-cidr = "0.0.0.0/0"
  nat-gw-id = aws_nat_gateway.main-NatGW.id
  rt-vpc-id = module.main-vpc.vpc-id
}

module "prublic-rt" {
  source = "./modules/public-rt-mod"
  rt-name = "public-rt"
  route-cidr = "0.0.0.0/0"
  igw-id =  aws_internet_gateway.main-IGW.id
  rt-vpc-id = module.main-vpc.vpc-id
}

#############################
#  route tables association #
#############################

resource "aws_route_table_association" "a" {
  subnet_id      = module.private_subnet_1.private-sub-id
  route_table_id = module.private-rt.rt-id
}

resource "aws_route_table_association" "b" {
  subnet_id      = module.private_subnet_2.private-sub-id
  route_table_id = module.private-rt.rt-id
}

resource "aws_route_table_association" "c" {
  subnet_id      = module.public_subnet_1.public-id
  route_table_id = module.prublic-rt.rt-id
}

resource "aws_route_table_association" "d" {
  subnet_id      = module.public_subnet_2.public-id
  route_table_id = module.prublic-rt.rt-id
}

#####################
#  security groups  #
#####################

# 1-for public instances(proxy server)
resource "aws_security_group" "public_traffic" {
  name        = "proxy_server_SG"
  description = "Allow http, ssh inbound traffic and all outbound traffic"
  vpc_id      = module.main-vpc.vpc-id

  tags = {
    Name = "proxy_server"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.public_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.public_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.public_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}




# 2-for private instances
resource "aws_security_group" "private_traffic" {
  name        = "privae_server_SG"
  description = "Allow http, ssh only from inside the vpc network"
  vpc_id      = module.main-vpc.vpc-id

  tags = {
    Name = "Backend_server"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_backend" {
  security_group_id = aws_security_group.private_traffic.id
  cidr_ipv4 = "10.0.0.0/16"
  from_port = 80
  ip_protocol = "tcp"
  to_port = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_backend" {
  security_group_id = aws_security_group.private_traffic.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_private" {
  security_group_id = aws_security_group.private_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

###############
#  aws image  #
###############

data "aws_ami" "amazon_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############
# key pair #
############

resource "aws_key_pair" "deployer" {
  key_name   = "project-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCga+JDpDAL6asf1OYlo0/4PNnZNHzgh2KagB7Ii01B8HSRZQoZaGka5RO+vPoalHepcEu3o65chOCYCqXhxMrn7qSmNY9i2Qg6CO1muNnlLmia1fgxGBrB0H35ZAtrnBquCTFqocMV994uWLl7tycJIlEqExmgfpWYGxKhanHe6fV88Dl5Zj8uPYQ9V+xRcqoufGJz5fS/L5rbeC9IXXFm0T6p6KZVPQRhhjcXCqMuuWYzqGwPF1DOklbnK0CbdxZD1Ejrolts5bWqHuVg1tvAKNavgR1LOvVBuuTB2GQFjy7f1nIxWjYfGqfZMrOmK4WOuJ+cFdiZ8GgQc3mxkX0L Karim Khalid@LAPTOP-FFEC8RCF"
}

##################
#  proxy server  #
##################

module "proxy_server_1" {
  source = "./modules/proxy-server-mod"
  img = data.aws_ami.amazon_ami.id
  backend_ip = aws_lb.back_end_alb.dns_name
  key = aws_key_pair.deployer.key_name
  sg = [aws_security_group.public_traffic.id]
  subnet = module.public_subnet_1.public-id
}

module "proxy_server_2" {
  source = "./modules/proxy-server-mod"
  img = data.aws_ami.amazon_ami.id
  backend_ip = aws_lb.back_end_alb.dns_name
  key = aws_key_pair.deployer.key_name
  sg = [aws_security_group.public_traffic.id]
  subnet = module.public_subnet_2.public-id
}

####################
#  private server  #
####################

module "backend_server_1" {
  source = "./modules/backend-instance"
  img = data.aws_ami.amazon_ami.id
  key = aws_key_pair.deployer.key_name
  key_path = file("C:/.ssh/project-key")
  sg = [aws_security_group.private_traffic.id]
  subnet = module.private_subnet_1.private-sub-id
}

module "backend_server_2" {
  source = "./modules/backend-instance"
  img = data.aws_ami.amazon_ami.id
  key = aws_key_pair.deployer.key_name
  key_path = file("C:/.ssh/project-key")
  sg = [aws_security_group.private_traffic.id]
  subnet = module.private_subnet_2.private-sub-id
}

#################
#  backend alb  #
#################

resource "aws_lb" "back_end_alb" {
  name               = "back-end-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.private_traffic.id]
  subnets            = [module.private_subnet_1.private-sub-id,module.private_subnet_2.private-sub-id]
}

resource "aws_lb_target_group" "backend_target_group" {
  name     = "backend-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.main-vpc.vpc-id
}

resource "aws_lb_target_group_attachment" "be_tg_instance1" {
  target_group_arn = aws_lb_target_group.backend_target_group.arn
  target_id        = module.backend_server_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "be_tg_instance2" {
  target_group_arn = aws_lb_target_group.backend_target_group.arn
  target_id        = module.backend_server_2.id
  port             = 80
}

resource "aws_lb_listener" "be_listener" {
  load_balancer_arn = aws_lb.back_end_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_target_group.arn
  }
}

##################
#  frontend alb  #
##################

resource "aws_lb" "front_end_alb" {
  name               = "front-end-alb"
  internal           = false                     
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_traffic.id]
  subnets            = [
    module.public_subnet_1.public-id,
    module.public_subnet_2.public-id
  ]
}

resource "aws_lb_target_group" "proxy_target_group" {
  name     = "proxy-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.main-vpc.vpc-id
  
}


resource "aws_lb_target_group_attachment" "proxy_tg_instance1" {
  target_group_arn = aws_lb_target_group.proxy_target_group.arn
  target_id        = module.proxy_server_1.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "proxy_tg_instance2" {
  target_group_arn = aws_lb_target_group.proxy_target_group.arn
  target_id        = module.proxy_server_2.id
  port             = 80
}

resource "aws_lb_listener" "fe_listener" {
  load_balancer_arn = aws_lb.front_end_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.proxy_target_group.arn
  }
}
