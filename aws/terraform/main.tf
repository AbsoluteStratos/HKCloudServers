# Based on
# https://github.com/terraform-google-modules/terraform-docs-samples/blob/main/compute/basic_vm/main.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance


resource "aws_security_group" "hollowknight" {
  name        = "hk-tf-security-group"
  description = "Security group for hollow knight servers"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.hollowknight.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  to_port   = 22
  ip_protocol = "tcp"
  description = "SSH"
}

resource "aws_vpc_security_group_ingress_rule" "hkmp" {
  security_group_id = aws_security_group.hollowknight.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = var.hkmp_port
  to_port   = var.hkmp_port
  ip_protocol = "udp"
  description = "HKMP"
}

resource "aws_vpc_security_group_ingress_rule" "hkmw" {
  security_group_id = aws_security_group.hollowknight.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = var.hkmw_port
  to_port   = var.hkmw_port
  ip_protocol = "tcp"
  description = "HKMP"
}

resource "aws_vpc_security_group_egress_rule" "hkmw" {
  security_group_id = aws_security_group.hollowknight.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
  description = "All traffic out"
}


resource "aws_instance" "hollow_knight_vm" {
  ami           = var.ami
  instance_type = var.machine_type
  key_name = var.key_pair
  vpc_security_group_ids  = ["${aws_security_group.hollowknight.id}"]

  root_block_device {
    volume_size       = 10
    volume_type = "gp3"
  }

  user_data = file("install_docker.sh")

  tags = {
    Name = var.vm_name
  }
}

output "instance_ip_address" {
  value = ["${aws_instance.hollow_knight_vm.*.public_ip}"]
  description = "The public IP address of the newly created instance"
}