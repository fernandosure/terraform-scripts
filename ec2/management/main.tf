# resource "aws_instance" "mediprocesos_settlement_instance" {
#   ami                    = "ami-03ed1e9e018845fbe"
#   instance_type          = "t3.large"
#   key_name               = "osigu-bastion-keypair"
#   vpc_security_group_ids = ["sg-b14361cd"]
#   subnet_id              = "subnet-4ebf8807"
#   iam_instance_profile   = "ecs-instance-role"

#   tags {
#     Name = "mediprocesos-settlement-instance"
#   }
# }


# output "mediprocesos_settlement_instance_private_ip" {
#   value = "${aws_instance.mediprocesos_settlement_instance.private_ip}"
# }


resource "aws_instance" "trueface_instance" {
  ami                    = "ami-0e8cfc180d75a62ce"
  instance_type          = "t2.xlarge"
  key_name               = "osigu-bastion-keypair"
  vpc_security_group_ids = ["sg-a65b56ee"]
  subnet_id              = "subnet-a78691ee"
  

  tags {
    Name = "trueface-instance"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.trueface_instance.id}"
  allocation_id = "eipalloc-09611ca4015360d76"
}


output "trueface_instance_private_ip" {
  value = "${aws_instance.trueface_instance.private_ip}"
}
