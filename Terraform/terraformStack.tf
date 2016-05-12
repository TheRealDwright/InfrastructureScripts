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

resource "aws_eip" "1" {
}

resource "aws_eip" "2" {
}

resource "aws_subnet" "public_1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.public_subnet_cidr_1}"
    map_public_ip_on_launch = true
    availability_zone = "${var.availability_zone_1}"
}

resource "aws_subnet" "public_2" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.public_subnet_cidr_2}"
    map_public_ip_on_launch = true
    availability_zone = "${var.availability_zone_2}"
}

resource "aws_subnet" "private_1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.private_subnet_cidr_1}"
    map_public_ip_on_launch = false
    availability_zone = "${var.availability_zone_1}"
}

resource "aws_subnet" "private_2" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.private_subnet_cidr_2}"
    map_public_ip_on_launch = false
    availability_zone = "${var.availability_zone_2}"
}

resource "aws_subnet" "db_1" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.db_subnet_cidr_1}"
    map_public_ip_on_launch = false
    availability_zone = "${var.availability_zone_1}"
}

resource "aws_subnet" "db_2" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.db_subnet_cidr_2}"
    map_public_ip_on_launch = false
    availability_zone = "${var.availability_zone_2}"
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
        gateway_id = "${aws_nat_gateway.1.id}"
    }
}

resource "aws_route_table" "private_2" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_nat_gateway.2.id}"
    }
}

resource "aws_route_table_association" "public_1" {
    route_table_id = "${aws_route_table.public.id}"
    subnet_id = "${aws_subnet.public_1.id}"
}

resource "aws_route_table_association" "public_2" {
    route_table_id = "${aws_route_table.public.id}"
    subnet_id = "${aws_subnet.public_2.id}"
}


resource "aws_route_table_association" "private_1" {
    route_table_id = "${aws_route_table.private_1.id}"
    subnet_id = "${aws_subnet.private_1.id}"
}

resource "aws_route_table_association" "private_2" {
    route_table_id = "${aws_route_table.private_2.id}"
    subnet_id = "${aws_subnet.private_2.id}"
}

resource "aws_route_table_association" "db_1" {
    route_table_id = "${aws_route_table.private_1.id}"
    subnet_id = "${aws_subnet.db_1.id}"
}

resource "aws_route_table_association" "db_2" {
    route_table_id = "${aws_route_table.private_2.id}"
    subnet_id = "${aws_subnet.db_2.id}"
}

resource "aws_nat_gateway" "1" {
    allocation_id = "${aws_eip.1.id}"
    subnet_id = "${aws_subnet.public_1.id}"
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "2" {
    allocation_id = "${aws_eip.2.id}"
    subnet_id = "${aws_subnet.public_2.id}"
  depends_on = ["aws_internet_gateway.gw",]
}

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

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "atlas_artifact" "helloworld"{
  name = "simplehq/helloworld"
  type = "amazon.image"
  version = "latest"
}

resource "aws_elb" "helloworld" {
  name = "helloworld-elb"
  subnets = ["${aws_subnet.public_1.id}", "${aws_subnet.public_2.id}"]
  internal = false
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  security_groups = ["${aws_security_group.allow_all.id}"]

    listener {
      instance_port = 8080
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
    }

    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "HTTP:8080/"
      interval = 30
    }

  tags {
    Name = "helloworld-terraform-elb"
  }
}

resource "aws_launch_configuration" "helloworld" {
    name_prefix = "terraform-lc-${atlas_artifact.helloworld.name}"
    image_id = "${atlas_artifact.helloworld.metadata_full.region-us-west-2}"
    instance_type = "t2.micro"
    key_name = "cameron-test"
    security_groups = ["${aws_security_group.allow_all.id}"]

    root_block_device {
      volume_type = "gp2"
      volume_size = "8"
      delete_on_termination = "true"
    }

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "helloworld" {
    name = "helloworld-example"
    launch_configuration = "${aws_launch_configuration.helloworld.name}"
    availability_zones = ["${var.availability_zone_1}", "${var.availability_zone_2}"]
    vpc_zone_identifier = ["${aws_subnet.private_1.id}", "${aws_subnet.private_2.id}"]
    max_size = 5
    min_size = 2
    health_check_grace_period = 300
    health_check_type = "ELB"
    desired_capacity = 4
    force_delete = true
    load_balancers = ["${aws_elb.helloworld.name}"]

    lifecycle {
      create_before_destroy = true
    }
}
