module "vpc" {
  #source                        = "terraform-aws-modules/vpc/aws"
  source                        = "../../modules/vpc"
  default_vpc_name              = "osigu-sandbox"
  name                          = "osigu-sandbox"
  cidr                          = "10.11.0.0/16"


  azs                           = ["us-east-1a", "us-east-1b",, "us-east-1c", "us-east-1d", "us-east-1e"]
  private_subnets               = ["10.11.11.0/24", "10.11.21.0/24", "10.11.31.0/24", "10.11.41.0/24", "10.11.51.0/24"]
  public_subnets                = ["10.11.10.0/24", "10.11.20.0/24", "10.11.30.0/24", "10.11.40.0/24", "10.11.50.0/24"]
  database_subnets              = ["10.11.19.0/24", "10.11.29.0/24"]

  enable_nat_gateway            = true
  enable_vpn_gateway            = true
  create_database_subnet_group  = true
  single_nat_gateway            = true

  tags                          = {
    Environment = "sandbox"
  }
}

###########################################################
################### Peering connection ####################
###########################################################

data "aws_vpc" "management_vpc" {
  id = "vpc-a1058bc7"
}

data "aws_route_table" "management_public_rtb" {
  vpc_id = "${data.aws_vpc.management_vpc.id}"
  tags {
    Name = "*dmz*"
  }
}

data "aws_route_table" "management_private_rtb" {
  vpc_id = "${data.aws_vpc.management_vpc.id}"
  tags {
    Name = "*private*"
  }
}


resource "aws_vpc_peering_connection" "management_peering" {
  peer_vpc_id   = "${module.vpc.vpc_id}"
  vpc_id        = "${data.aws_vpc.management_vpc.id}"
  auto_accept   = true

  tags {
    Name = "osigu-mgmt-sandbox-pcx"
  }
}

resource "aws_route" "from_sandbox_public_to_management_peering_route" {
  route_table_id         = "${element(module.vpc.public_route_table_ids, count.index)}"
  destination_cidr_block = "${data.aws_vpc.management_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.management_peering.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "from_sandbox_private_to_management_peering_route" {
  route_table_id         = "${element(module.vpc.private_route_table_ids, count.index)}"
  destination_cidr_block = "${data.aws_vpc.management_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.management_peering.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "from_management_private_to_sandbox_peering_route" {
  route_table_id         = "${data.aws_route_table.management_private_rtb.id}"
  destination_cidr_block = "${module.vpc.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.management_peering.id}"

  timeouts {
    create = "5m"
  }
}
