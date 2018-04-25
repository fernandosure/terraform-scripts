## variables
variable "rds_cluster_name" {
  description = "RDS Cluster name"
}

variable "rds_db_name" {
  description = "RDS database name"
}

variable "rds_db_engine" {
  description = "RDS database engine"
}

variable "rds_master_username" {
  description = "RDS database master username"
}

variable "rds_master_password" {
  description = "RDS database master password"
}

variable "rds_security_groups"{
  description = "RDS Security groups"
  default = []
}

variable "rds_instance_class" {
  description = "RDS Instance class"
}

variable "rds_vpc_subnet_ids" {
  description ="RDS VPC subnet ids"
  default = []
}



resource "aws_db_instance" "rds_postgresql_instance" {
  allocated_storage    = "${var.rds_allocated_storage}"
  storage_type         = "gp2"
  engine               = "postgresql"
  instance_class       = "${var.rds_instance_class}"
  name                 = "${var.rds_db_name}"
  username             = "${var.rds_master_username}"
  password             = "${var.rds_master_password}"
  db_subnet_group_name = "${aws_db_subnet_group.db_subnet_group.name}"
  vpc_security_group_ids = ["${aws_security_group.db_security_group.id}"]

  tags {
      Name         = "${var.rds_cluster_name}-db-cluster"
      ManagedBy    = "terraform"
  }

  lifecycle {
      create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {

    name          = "${var.rds_cluster_name}-db-subnet-group"
    description   = "Allowed subnets for db cluster instances"
    subnet_ids    = ["${var.rds_vpc_subnet_ids}"]

    tags {
        Name         = "${var.rds_cluster_name}-db-subnet-group"
        ManagedBy    = "terraform"
    }
}
