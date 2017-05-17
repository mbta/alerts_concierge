provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

/* Network configuration for the environment */

# Create a VPC to launch our instances into
resource "aws_vpc" "primary" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "primary" {
  vpc_id = "${aws_vpc.primary.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.primary.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.primary.id}"

  lifecycle {
    create_before_destroy = "true"
  }
}

# Create subnets
resource "aws_subnet" "primary" {
  vpc_id                  = "${aws_vpc.primary.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.primary-az}"
}

resource "aws_subnet" "secondary" {
  vpc_id                  = "${aws_vpc.primary.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone =  "${var.secondary-az}"
}