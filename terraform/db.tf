resource "aws_db_subnet_group" "sg_redash_rds" {
  name = "sg_redash_rds"
  subnet_ids = [
    aws_subnet.social_dashboard_subnet_private_a.id,
    aws_subnet.social_dashboard_subnet_private_c.id
  ]

  depends_on = [
    aws_subnet.social_dashboard_subnet_private_a,
    aws_subnet.social_dashboard_subnet_private_c,
  ]
}

resource "aws_db_parameter_group" "pg_redash_rds" {
  name   = "pg-redash-rds"
  family = "postgres13"
}

resource "aws_db_instance" "redash_rds" {
  allocated_storage          = 20
  engine                     = "postgres"
  engine_version             = "13.2"
  instance_class             = "db.t3.micro"
  name                       = "redash_rds"
  username                   = var.redash_db_user_name
  password                   = var.redash_db_user_password
  parameter_group_name       = aws_db_parameter_group.pg_redash_rds.name
  skip_final_snapshot        = true
  auto_minor_version_upgrade = true
  multi_az                   = true
  backup_window              = "15:00-17:00"
  maintenance_window         = "Sat:17:00-Sat:19:00"
  publicly_accessible        = false
  db_subnet_group_name       = aws_db_subnet_group.sg_redash_rds.name
  vpc_security_group_ids = [
    aws_security_group.rds_redash_sg.id
  ]

  depends_on = [
    aws_db_parameter_group.pg_redash_rds,
    aws_security_group.rds_redash_sg,
    aws_db_subnet_group.sg_redash_rds,
  ]
}
