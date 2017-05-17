resource "aws_db_instance" "mbta-staging" {
  depends_on             = ["aws_security_group.db-primary"]
  identifier             = "mbta-server-staging"
  allocated_storage      = "50"
  storage_type           = "gp2" # Consider IOPS?
  engine                 = "postgres"
  engine_version         = "9.5.4"
  instance_class         = "db.t2.small"
  name                   = "mbta_server_staging"
  username               = "${var.db_username}"
  password               = "${var.db_password}"
  vpc_security_group_ids = ["${aws_security_group.db-primary.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.default.id}"
}

resource "aws_db_subnet_group" "default" {
  name        = "mbta-server-db-subnet-group"
  description = "Staging DB subnet group"
  subnet_ids  = [
    "${aws_subnet.primary.id}",
    "${aws_subnet.secondary.id}"
  ]
}

resource "aws_security_group" "db-primary" {
  name        = "mbta-db-primary"
  description = "Security Group for primary DB"
  vpc_id      = "${aws_vpc.primary.id}"

  # TCP access from the VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "TCP"
    cidr_blocks = ["${aws_vpc.primary.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}