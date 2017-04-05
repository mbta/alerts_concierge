resource "aws_instance" "build-server" {
  connection {
    user = "ubuntu"
  }

  instance_type = "t2.small"

  ami = "${var.build-ami-id}"

  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.build-server.id}"]

  subnet_id = "${aws_subnet.secondary.id}"

  associate_public_ip_address = "true"

  tags = {
    Name = "mbta-build-server"
  }
}

resource "aws_security_group" "build-server" {
  name        = "mbta-build-server-sg"
  description = "SG for MBTA build server"
  vpc_id      = "${aws_vpc.primary.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}