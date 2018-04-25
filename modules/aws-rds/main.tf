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


resource "aws_rds_cluster" "rds_cluster" {
    cluster_identifier            = "${var.rds_cluster_name}-db-cluster"
    database_name                 = "${var.rds_db_name}"
    engine                        = "${var.rds_db_engine}" # aurora-postgresql
    master_username               = "${var.rds_master_username}"
    master_password               = "${var.rds_master_password}"
    backup_retention_period       = 5
    preferred_backup_window       = "02:00-03:00"
    preferred_maintenance_window  = "wed:03:00-wed:04:00"
    db_subnet_group_name          = "${aws_db_subnet_group.db_subnet_group.name}"
    skip_final_snapshot           = true
    vpc_security_group_ids        = ["${var.rds_security_groups}"]

    tags {
        Name         = "${var.rds_cluster_name}-db-cluster"
        ManagedBy    = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_rds_cluster_instance" "rds_db_cluster_instance" {
    count                 = "1"
    identifier            = "${var.rds_cluster_name}-db-instance"
    cluster_identifier    = "${aws_rds_cluster.rds_cluster.id}"
    instance_class        = "${var.rds_instance_class}" # "db.r4.large"
    engine                = "${var.rds_db_engine}" #"aurora-postgresql"
    engine_version        = "9.6.3"
    db_subnet_group_name  = "${aws_db_subnet_group.db_subnet_group.name}"
    publicly_accessible   = false

    tags {
        Name         = "${var.rds_cluster_name}-db-instance"
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
