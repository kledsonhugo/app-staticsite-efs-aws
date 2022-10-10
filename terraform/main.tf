data "aws_caller_identity" "current" {}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "sn1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "sn2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1c"
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rt_sn1" {
  subnet_id      = aws_subnet.sn1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rt_sn2" {
  subnet_id      = aws_subnet.sn2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_efs_file_system" "efs" {
  #  availability_zone_name = "us-east-1a"
  encrypted = false
}

resource "aws_efs_file_system_policy" "efs_policy" {
  file_system_id                     = aws_efs_file_system.efs.id
  bypass_policy_lockout_safety_check = true
  policy                             = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "efs-policy-efs",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "elasticfilesystem:*"
            ],
            "Resource": [
                "arn:aws:elasticfilesystem:us-east-1:${data.aws_caller_identity.current.account_id}:file-system/${aws_efs_file_system.efs.id}"
            ]
        }
    ]
}
POLICY
}

resource "aws_efs_mount_target" "mount1" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.sn1.id
  security_groups = [aws_security_group.sg.id]
}

resource "aws_efs_mount_target" "mount2" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.sn2.id
  security_groups = [aws_security_group.sg.id]
}

data "template_file" "user_data" {
  template = file("./scripts/user_data.sh")
  vars = {
    efs_id = aws_efs_file_system.efs.id
  }
}

# resource "aws_instance" "instance" {
#   count                  = 4
#   ami                    = "ami-02e136e904f3da870"
#   instance_type          = "t2.micro"
#   key_name               = "vockey"
#   subnet_id              = aws_subnet.sn.id
#   vpc_security_group_ids = [aws_security_group.sg.id]
#   user_data              = base64encode(data.template_file.user_data.rendered)
#   depends_on = [
#     aws_efs_mount_target.efs_target
#   ]
# }

resource "aws_launch_template" "lt" {
  name                   = "ltemplate"
  image_id               = "ami-02e136e904f3da870"
  instance_type          = "t2.micro"
  key_name               = "vockey"
  user_data              = base64encode(data.template_file.user_data.rendered)
  vpc_security_group_ids = [aws_security_group.sg.id]
}

resource "aws_lb" "lb" {
  name               = "lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.sn1.id, aws_subnet.sn2.id]
  security_groups    = [aws_security_group.sg.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "tg"
  protocol = "HTTP"
  port     = "80"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener" "ec2_lb_listener" {
  protocol          = "HTTP"
  port              = "80"
  load_balancer_arn = aws_lb.lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "asg"
  desired_capacity    = "4"
  min_size            = "2"
  max_size            = "8"
  vpc_zone_identifier = [aws_subnet.sn1.id, aws_subnet.sn2.id]
  target_group_arns   = [aws_lb_target_group.tg.arn]
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  depends_on = [
    aws_efs_mount_target.mount1,
    aws_efs_mount_target.mount2
  ]
}