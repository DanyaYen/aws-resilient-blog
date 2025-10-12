# --- Security Group RDS ---
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow traffic from EKS nodes to RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.main_cluster.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}


# --- DB Subnet Group ---
resource "aws_db_subnet_group" "main_db_subnet_group" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "Main DB Subnet Group"
  }
}


# --- RDS INSTANCE ---
resource "aws_db_instance" "main_db" {
  identifier           = "main-db-instance"
  engine               = "mariadb"
  engine_version       = "10.6"
  instance_class       = "db.t2.micro"
  allocated_storage    = 20
  db_name              = "wordpressdb"
  username             = "admin"
  password             = "YourSuperSecurePassword123!"
  db_subnet_group_name = aws_db_subnet_group.main_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
}