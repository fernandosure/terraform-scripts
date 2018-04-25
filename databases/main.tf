########################
## Variables
########################
variable "environment_name"             	   {}
variable "rds_vpc_id"                   	   {}
variable "rds_subnets_prefix"           	   {}
variable "rds_db_name"                  	   {}
variable "rds_master_username"          	   {}
variable "rds_master_password"          	   {}
variable "rds_instance_class"           	   {}
variable "rds_allocated_storage"        	   {}
variable "ec2_key_pair"                 	   {}
variable "rds_sg_ingress_cidr"          	   {}
variable "rds_sg_ingress_subnet"        	   {}
variable "management_private_subnet"	       {}
variable "management_private_vpc"            {}
variable "management_private_subnet_prefix"  {}



data "aws_subnet_ids" "rds_subnets" {
  vpc_id = "${var.rds_vpc_id}"
  tags {
    Name = "${var.rds_subnets_prefix}"
  }
}

module rds_aurora_instance {
  source = "./modules/aws-rds"

  rds_cluster_name    = "rds-aurora"
  rds_db_name         = "${var.rds_db_name}"
  rds_db_engine       = "aurora-postgresql"
  rds_master_username = "${var.rds_master_username}"
  rds_master_password = "${var.rds_master_password}"
  rds_security_groups = ["${aws_security_group.db_security_group.id}"]
  rds_instance_class  = "${var.rds_instance_class}"
  rds_vpc_subnet_ids  = "${data.aws_subnet_ids.rds_subnets.ids}"
}

resource "aws_db_instance" "rds_postgresql_instance" {
  identifier              = "postgresql-db-instance"
  allocated_storage       = "${var.rds_allocated_storage}"
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "9.6.3"
  instance_class          = "${var.rds_instance_class}"
  name                    = "${var.rds_db_name}"
  username                = "${var.rds_master_username}"
  password                = "${var.rds_master_password}"
  skip_final_snapshot     = true
  db_subnet_group_name    = "${aws_db_subnet_group.postgresql_db_subnet_group.name}"
  vpc_security_group_ids  = ["${aws_security_group.db_security_group.id}"]

  tags {
      Name         = "postgresql-db-instance"
      ManagedBy    = "terraform"
  }

  lifecycle {
      create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "postgresql_db_subnet_group" {

    name          = "postgresql-db-subnet-group"
    description   = "Allowed subnets for db cluster instances"
    subnet_ids    = ["${data.aws_subnet_ids.rds_subnets.ids}"]

    tags {
        Name         = "postgresql-db-subnet-group"
        ManagedBy    = "terraform"
    }
}


resource "aws_security_group" "db_security_group" {
  name          = "${var.environment_name}-db-security-group"
  description   = "${var.environment_name}-db-security-group"
  vpc_id        = "${var.rds_vpc_id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${var.rds_sg_ingress_cidr}"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = ["${var.rds_sg_ingress_subnet}"]
  }

  // This is for outbound internet access
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
      Name         = "${var.environment_name}-db-security-group"
      ManagedBy    = "terraform"
  }
}

resource "aws_instance" "db_test_instance" {
  ami                         = "ami-1853ac65"
  key_name                    = "${var.ec2_key_pair}"
  instance_type               = "r4.xlarge"
  vpc_security_group_ids      = ["${data.aws_security_group.management_private_sg.id}"]
  subnet_id                   = "${var.management_private_subnet}"
  associate_public_ip_address = false

  tags {
      Name         = "${var.environment_name}-db-instance"
      ManagedBy    = "terraform"
      Environment  = "${var.environment_name}"
  }
}

resource "aws_instance" "db_test_instance_postgres" {
  ami                         = "ami-1853ac65"
  key_name                    = "${var.ec2_key_pair}"
  instance_type               = "r4.xlarge"
  vpc_security_group_ids      = ["${data.aws_security_group.management_private_sg.id}"]
  subnet_id                   = "${var.management_private_subnet}"
  associate_public_ip_address = false

  tags {
      Name         = "postgres-test-db-instance"
      ManagedBy    = "terraform"
      Environment  = "${var.environment_name}"
  }
}


data "aws_subnet_ids" "management_private_subnets" {
  vpc_id = "${var.management_private_vpc}"
  tags {
    Name = "${var.management_private_subnet_prefix}"
  }
}

data "aws_security_group" "management_private_sg" {
  name = "${var.management_private_sg_prefix}"
}
