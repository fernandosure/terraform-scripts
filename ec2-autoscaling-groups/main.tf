variable "docker_auth_token"          {}
variable "backend_ecs_keypair"        {}
variable "shutdown_schedule"          {}
variable "start_schedule"             {}
variable "ecs_ami_id"                 {}
variable "ecs_spot_price"             {}

variable "backend_availability_zones" { default = [] }
variable "backend_subnets"            { default = [] }
variable "backend_security_groups"    { default = [] }


############################################################
######################## SANDBOX
############################################################
data "template_file" "sandbox_ec2_user_data" {
  template = "${file("cloud-init.tpl")}"

  vars {
    ecs_cluster = "sandbox"
    docker_auth_token = "${var.docker_auth_token}"
  }
}

resource "aws_launch_configuration" "sandbox_launch_configuration" {
  name                    = "sandbox-launch-configuration-spot-${var.ecs_spot_price}-${var.ecs_ami_id}"
  image_id                = "${var.ecs_ami_id}"
  iam_instance_profile    = "ecs-instance-profile"
  key_name                = "${var.backend_ecs_keypair}"
  instance_type           = "r4.large"
  spot_price              = "${var.ecs_spot_price}"
  security_groups         = "${var.backend_security_groups}"
  user_data               = "${data.template_file.sandbox_ec2_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "sandbox_autoscaling_group_spot" {
  name                      = "sandbox-autoscaling-group-spot"
  launch_configuration      = "${aws_launch_configuration.sandbox_launch_configuration.name}"
  max_size                  = 0
  min_size                  = 0
  desired_capacity          = 0

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
    value               = "sandbox"
    propagate_at_launch = true
  }

  lifecycle {
      create_before_destroy = true
  }
}


resource "aws_autoscaling_schedule" "sandbox_start" {
  autoscaling_group_name = "${aws_autoscaling_group.sandbox_autoscaling_group_spot.name}"
  scheduled_action_name  = "startup"
  max_size               = 2
  min_size               = 2
  desired_capacity       = 2
  recurrence             = "${var.start_schedule}"
}

resource "aws_autoscaling_schedule" "sandbox_shutdown" {
  autoscaling_group_name = "${aws_autoscaling_group.sandbox_autoscaling_group_spot.name}"
  scheduled_action_name  = "shutdown"
  max_size               = 0
  min_size               = 0
  desired_capacity       = 0
  recurrence             = "${var.shutdown_schedule}"
}


############################################################
######################## DEV
############################################################
data "template_file" "dev_ec2_user_data" {
  template = "${file("cloud-init.tpl")}"

  vars {
    ecs_cluster = "dev"
    docker_auth_token = "${var.docker_auth_token}"
  }
}

resource "aws_launch_configuration" "dev_launch_configuration" {
  name                    = "dev-launch-configuration-spot-${var.ecs_spot_price}-${var.ecs_ami_id}"
  image_id                = "${var.ecs_ami_id}"
  iam_instance_profile    = "ecs-instance-profile"
  key_name                = "${var.backend_ecs_keypair}"
  instance_type           = "r4.large"
  spot_price              = "${var.ecs_spot_price}"
  security_groups         = "${var.backend_security_groups}"
  user_data               = "${data.template_file.dev_ec2_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "dev_autoscaling_group_spot" {
  name                      = "dev-autoscaling-group-spot"
  launch_configuration      = "${aws_launch_configuration.dev_launch_configuration.name}"
  max_size                  = 0
  min_size                  = 0
  desired_capacity          = 0

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
    value               = "dev"
    propagate_at_launch = true
  }

  lifecycle {
      create_before_destroy = true
  }
}


resource "aws_autoscaling_schedule" "dev_start" {
  autoscaling_group_name = "${aws_autoscaling_group.dev_autoscaling_group_spot.name}"
  scheduled_action_name  = "startup"
  max_size               = 2
  min_size               = 2
  desired_capacity       = 2
  recurrence             = "${var.start_schedule}"
}

resource "aws_autoscaling_schedule" "dev_shutdown" {
  autoscaling_group_name = "${aws_autoscaling_group.dev_autoscaling_group_spot.name}"
  scheduled_action_name  = "shutdown"
  max_size               = 0
  min_size               = 0
  desired_capacity       = 0
  recurrence             = "${var.shutdown_schedule}"
}

############################################################
######################## QA1
############################################################

data "template_file" "qa1_ec2_user_data" {
  template = "${file("cloud-init.tpl")}"

  vars {
    ecs_cluster = "qa1"
    docker_auth_token = "${var.docker_auth_token}"
  }
}

resource "aws_launch_configuration" "qa1_launch_configuration" {
  name                    = "qa1-launch-configuration-spot-${var.ecs_spot_price}-${var.ecs_ami_id}"
  image_id                = "${var.ecs_ami_id}"
  iam_instance_profile    = "ecs-instance-profile"
  key_name                = "${var.backend_ecs_keypair}"
  instance_type           = "r4.large"
  spot_price              = "${var.ecs_spot_price}"
  security_groups         = "${var.backend_security_groups}"
  user_data               = "${data.template_file.qa1_ec2_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "qa1_autoscaling_group_spot" {
  name                      = "qa1-autoscaling-group-spot"
  launch_configuration      = "${aws_launch_configuration.qa1_launch_configuration.name}"
  max_size                  = 0
  min_size                  = 0
  desired_capacity          = 0

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
    value               = "qa1"
    propagate_at_launch = true
  }

  lifecycle {
      create_before_destroy = true
  }
}


resource "aws_autoscaling_schedule" "qa1_start" {
  autoscaling_group_name = "${aws_autoscaling_group.qa1_autoscaling_group_spot.name}"
  scheduled_action_name  = "startup"
  max_size               = 2
  min_size               = 2
  desired_capacity       = 2
  recurrence             = "${var.start_schedule}"
}

resource "aws_autoscaling_schedule" "qa1_shutdown" {
  autoscaling_group_name = "${aws_autoscaling_group.qa1_autoscaling_group_spot.name}"
  scheduled_action_name  = "shutdown"
  max_size               = 0
  min_size               = 0
  desired_capacity       = 0
  recurrence             = "${var.shutdown_schedule}"
}

############################################################
######################## QA2
############################################################
data "template_file" "qa2_ec2_user_data" {
  template = "${file("cloud-init.tpl")}"

  vars {
    ecs_cluster = "qa2"
    docker_auth_token = "${var.docker_auth_token}"
  }
}

resource "aws_launch_configuration" "qa2_launch_configuration" {
  name                    = "qa2-launch-configuration-spot-${var.ecs_spot_price}-${var.ecs_ami_id}"
  image_id                = "${var.ecs_ami_id}"
  iam_instance_profile    = "ecs-instance-profile"
  key_name                = "${var.backend_ecs_keypair}"
  instance_type           = "r4.large"
  spot_price              = "${var.ecs_spot_price}"
  security_groups         = "${var.backend_security_groups}"
  user_data               = "${data.template_file.qa2_ec2_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "qa2_autoscaling_group_spot" {
  name                      = "qa2-autoscaling-group-spot"
  launch_configuration      = "${aws_launch_configuration.qa2_launch_configuration.name}"
  max_size                  = 0
  min_size                  = 0
  desired_capacity          = 0

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
    value               = "qa2"
    propagate_at_launch = true
  }

  lifecycle {
      create_before_destroy = true
  }
}


resource "aws_autoscaling_schedule" "qa2_start" {
  autoscaling_group_name = "${aws_autoscaling_group.qa2_autoscaling_group_spot.name}"
  scheduled_action_name  = "startup"
  max_size               = 2
  min_size               = 2
  desired_capacity       = 2
  recurrence             = "${var.start_schedule}"
}

resource "aws_autoscaling_schedule" "qa2_shutdown" {
  autoscaling_group_name = "${aws_autoscaling_group.qa2_autoscaling_group_spot.name}"
  scheduled_action_name  = "shutdown"
  max_size               = 0
  min_size               = 0
  desired_capacity       = 0
  recurrence             = "${var.shutdown_schedule}"
}

############################################################
######################## QA3
############################################################
data "template_file" "qa3_ec2_user_data" {
  template = "${file("cloud-init.tpl")}"

  vars {
    ecs_cluster = "qa3"
    docker_auth_token = "${var.docker_auth_token}"
  }
}

resource "aws_launch_configuration" "qa3_launch_configuration" {
  name                    = "qa3-launch-configuration-spot-${var.ecs_spot_price}-${var.ecs_ami_id}"
  image_id                = "${var.ecs_ami_id}"
  iam_instance_profile    = "ecs-instance-profile"
  key_name                = "${var.backend_ecs_keypair}"
  instance_type           = "r4.large"
  spot_price              = "${var.ecs_spot_price}"
  security_groups         = "${var.backend_security_groups}"
  user_data               = "${data.template_file.qa3_ec2_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "qa3_autoscaling_group_spot" {
  name                      = "qa3-autoscaling-group-spot"
  launch_configuration      = "${aws_launch_configuration.qa3_launch_configuration.name}"
  max_size                  = 0
  min_size                  = 0
  desired_capacity          = 0

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
    value               = "qa3"
    propagate_at_launch = true
  }

  lifecycle {
      create_before_destroy = true
  }
}


resource "aws_autoscaling_schedule" "qa3_start" {
  autoscaling_group_name = "${aws_autoscaling_group.qa3_autoscaling_group_spot.name}"
  scheduled_action_name  = "startup"
  max_size               = 2
  min_size               = 2
  desired_capacity       = 2
  recurrence             = "${var.start_schedule}"
}

resource "aws_autoscaling_schedule" "qa3_shutdown" {
  autoscaling_group_name = "${aws_autoscaling_group.qa3_autoscaling_group_spot.name}"
  scheduled_action_name  = "shutdown"
  max_size               = 0
  min_size               = 0
  desired_capacity       = 0
  recurrence             = "${var.shutdown_schedule}"
}


############################################################
######################## QA4
############################################################
data "template_file" "qa4_ec2_user_data" {
  template = "${file("cloud-init.tpl")}"

  vars {
    ecs_cluster = "qa4"
    docker_auth_token = "${var.docker_auth_token}"
  }
}

resource "aws_launch_configuration" "qa4_launch_configuration" {
  name                    = "qa4-launch-configuration-spot-${var.ecs_spot_price}-${var.ecs_ami_id}"
  image_id                = "${var.ecs_ami_id}"
  iam_instance_profile    = "ecs-instance-profile"
  key_name                = "${var.backend_ecs_keypair}"
  instance_type           = "r4.large"
  spot_price              = "${var.ecs_spot_price}"
  security_groups         = "${var.backend_security_groups}"
  user_data               = "${data.template_file.qa4_ec2_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "qa4_autoscaling_group_spot" {
  name                      = "qa4-autoscaling-group-spot"
  launch_configuration      = "${aws_launch_configuration.qa4_launch_configuration.name}"
  max_size                  = 2
  min_size                  = 2
  desired_capacity          = 2

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
    value               = "qa4"
    propagate_at_launch = true
  }

  lifecycle {
      create_before_destroy = true
  }
}


resource "aws_autoscaling_schedule" "qa4_start" {
  autoscaling_group_name = "${aws_autoscaling_group.qa4_autoscaling_group_spot.name}"
  scheduled_action_name  = "startup"
  max_size               = 2
  min_size               = 2
  desired_capacity       = 2
  recurrence             = "${var.start_schedule}"
}

resource "aws_autoscaling_schedule" "qa4_shutdown" {
  autoscaling_group_name = "${aws_autoscaling_group.qa4_autoscaling_group_spot.name}"
  scheduled_action_name  = "shutdown"
  max_size               = 0
  min_size               = 0
  desired_capacity       = 0
  recurrence             = "${var.shutdown_schedule}"
}
