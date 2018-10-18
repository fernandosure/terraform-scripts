variable "vpc_id" {}
variable "docker_auth_token" {}
variable "backend_ecs_keypair" {}
variable "shutdown_schedule" {}
variable "start_schedule" {}
variable "ecs_ami_id" {}
variable "ecs_spot_price" {}

variable "backend_availability_zones" {
  default = []
}

variable "backend_security_groups" {
  default = []
}

#######################################################
########## private securicy group #####################
#######################################################
resource "aws_security_group" "private_sg" {
  name        = "osigu-sandbox-ecs-sg"
  description = "SG to allow access from elbs on public subnet and inside communication"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "osigu-sandbox-ecs-sg"
  }
}

resource "aws_security_group_rule" "private_sg_internet" {
  type              = "egress"
  security_group_id = "${aws_security_group.private_sg.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "outbound internet traffic"
}

resource "aws_security_group_rule" "private_sg_bastion" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.private_sg.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "sg-b14361cd"
  description              = "bastion host"
}

resource "aws_security_group_rule" "private_sg_vpn" {
  type              = "ingress"
  security_group_id = "${aws_security_group.private_sg.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.212.134.0/24"]
  description       = "OsiguHQ VPN forticlient"
}

resource "aws_security_group_rule" "private_sg_internal" {
  type              = "ingress"
  security_group_id = "${aws_security_group.private_sg.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  description       = "internal communication"
}

resource "aws_security_group_rule" "private_sg_admin_server" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.private_sg.id}"
  from_port                = 8961
  to_port                  = 8961
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.public_sg.id}"
  description              = "admin-server traffic"
}

resource "aws_security_group_rule" "private_sg_lb_traffic" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.private_sg.id}"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.public_sg.id}"
  description              = "Internet traffic from the ALB"
}

resource "aws_security_group_rule" "private_sg_rule_alb_healthcheck" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.private_sg.id}"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.public_sg.id}"
  description              = "Internet traffic from the ALB healthcheck"
}

#######################################################
########## public securicy group ######################
#######################################################
resource "aws_security_group" "public_sg" {
  name        = "osigu-sandbox-dmz-sg"
  description = "For ELBs and Publicly exposed resources only"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["181.114.13.182/32"]
    description = "OsiguHQ Columbus ISP"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["190.143.200.154/32"]
    description = "OsiguHQ TLK ISP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Internet traffic"
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    description      = "Internet traffic IPv6"
  }

  egress {
    from_port       = 8961
    to_port         = 8961
    protocol        = "tcp"
    security_groups = ["${aws_security_group.private_sg.id}"]
    description     = "admin-server traffic"
  }

  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["${aws_security_group.private_sg.id}"]
    description     = "Internet traffic to the zuul service"
  }

  egress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = ["${aws_security_group.private_sg.id}"]
    description     = "ALB health check"
  }

  tags {
    Name = "osigu-sandbox-dmz-sg"
  }
}

############################################################
######################## SANDBOX
############################################################
resource "aws_ecs_cluster" "sandbox" {
  name = "sandbox"
}

data "template_file" "sandbox_ec2_user_data" {
  template = "${file("cloud-init.tpl")}"

  vars {
    ecs_cluster       = "sandbox"
    docker_auth_token = "${var.docker_auth_token}"
  }
}

data "aws_subnet_ids" "ecs_subnets" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "osigu-sandbox-ecs-*"
  }
}

resource "aws_launch_configuration" "sandbox_launch_configuration" {
  name                 = "sandbox-launch-configuration-spot-${var.ecs_spot_price}-${var.ecs_ami_id}"
  image_id             = "${var.ecs_ami_id}"
  iam_instance_profile = "ecs-instance-profile"
  key_name             = "${var.backend_ecs_keypair}"
  instance_type        = "r4.large"
  spot_price           = "${var.ecs_spot_price}"
  security_groups      = ["${aws_security_group.private_sg.id}"]
  user_data            = "${data.template_file.sandbox_ec2_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "sandbox_autoscaling_group_spot" {
  name                 = "sandbox-autoscaling-group-spot"
  launch_configuration = "${aws_launch_configuration.sandbox_launch_configuration.name}"
  max_size             = 3
  min_size             = 3
  desired_capacity     = 3

  force_delete              = false
  health_check_type         = "EC2"
  health_check_grace_period = 0
  metrics_granularity       = ""
  availability_zones        = "${var.backend_availability_zones}"
  vpc_zone_identifier       = ["${data.aws_subnet_ids.ecs_subnets.ids}"]
  default_cooldown          = 300
  wait_for_capacity_timeout = "10m"

  tag {
    key                 = "Name"
    value               = "sandbox"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
#
# resource "aws_autoscaling_schedule" "sandbox_start" {
#   autoscaling_group_name = "${aws_autoscaling_group.sandbox_autoscaling_group_spot.name}"
#   scheduled_action_name  = "startup"
#   max_size               = 3
#   min_size               = 3
#   desired_capacity       = 3
#   recurrence             = "${var.start_schedule}"
# }
#
# resource "aws_autoscaling_schedule" "sandbox_shutdown" {
#   autoscaling_group_name = "${aws_autoscaling_group.sandbox_autoscaling_group_spot.name}"
#   scheduled_action_name  = "shutdown"
#   max_size               = 0
#   min_size               = 0
#   desired_capacity       = 0
#   recurrence             = "${var.shutdown_schedule}"
# }
