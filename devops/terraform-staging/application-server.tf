resource "aws_instance" "app-server" {
  connection {
    user = "ubuntu"
  }

  instance_type = "t2.small"

  ami = "${var.app-ami-id}"

  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.app-server.id}"]

  subnet_id = "${aws_subnet.secondary.id}"

  associate_public_ip_address = "true"

  tags = {
    Name = "mbta-app-server"
  }
}

resource "aws_security_group" "app-server" {
  name        = "mbta-app-server-sg"
  description = "SG for MBTA app server"
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

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}