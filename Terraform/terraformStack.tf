#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------
resource "aws_vpc" "main" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_eip" "one" {
}

resource "aws_eip" "two" {
}

resource "aws_subnet" "public_1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.public_subnet_cidr_1}"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.public_subnet_cidr_2}"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "private_1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.private_subnet_cidr_1}"
    map_public_ip_on_launch = false
}

resource "aws_subnet" "private_2" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.private_subnet_cidr_2}"
    map_public_ip_on_launch = false
}

resource "aws_subnet" "db_1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.db_subnet_cidr_1}"
    map_public_ip_on_launch = false
}

resource "aws_subnet" "db_2" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.db_subnet_cidr_2}"
    map_public_ip_on_launch = false
}

resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }
}

resource "aws_route_table" "private_1" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }
}

resource "aws_main_route_table_association" "public" {
    vpc_id = "${aws_vpc.main.id}"
    route_table_id = "${aws_route_table.public.id}"
}

resource "aws_nat_gateway" "one" {
    allocation_id = "aws_eip.two"

  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "two" {
    allocation_id = "aws_eip.two"

  depends_on = ["aws_internet_gateway.gw",]
}
#--------------------------------------------------------------
# Security Group
#--------------------------------------------------------------
resource "aws_security_group" "allow_all" {
  name = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}
