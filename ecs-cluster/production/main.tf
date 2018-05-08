variable "docker_auth_token"          {}
variable "backend_ecs_keypair"        {}
variable "ecs_ami_id"                 {}

variable "backend_availability_zones" { default = [] }
variable "backend_subnets"            { default = [] }
variable "backend_security_groups"    { default = [] }


############################################################
######################## PRODUCTION
############################################################
resource "aws_ecs_cluster" "prod" {
  name = "prod"
}

data "template_file" "prod_ec2_user_data" {
  template = "${file("cloud-init.tpl")}"

  vars {
    ecs_cluster = "prod"
    docker_auth_token = "${var.docker_auth_token}"
  }
}

resource "aws_launch_configuration" "prod_launch_configuration" {
  name                    = "prod-launch-configuration-${var.ecs_ami_id}"
  image_id                = "${var.ecs_ami_id}"
  iam_instance_profile    = "ecs-instance-profile"
  key_name                = "${var.backend_ecs_keypair}"
  instance_type           = "r4.large"
  security_groups         = "${var.backend_security_groups}"
  user_data               = "${data.template_file.prod_ec2_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "prod_autoscaling_group" {
  name                      = "prod-autoscaling-group"
  launch_configuration      = "${aws_launch_configuration.prod_launch_configuration.name}"
  max_size                  = 10
  min_size                  = 5
  desired_capacity          = 6

  force_delete              = false
  health_check_type         = "EC2"
  health_check_grace_period = 0
  metrics_granularity       = ""
  availability_zones        = "${var.backend_availability_zones}"
  vpc_zone_identifier       = "${var.backend_subnets}"
  default_cooldown          = 300
  wait_for_capacity_timeout = "10m"

  tag {
    key                 = "Name"
    value               = "prod"
    propagate_at_launch = true
  }

  lifecycle {
      create_before_destroy = true
  }
}
