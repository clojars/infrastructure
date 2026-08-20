data "aws_ssm_parameter" "db_password" {
  name = "/clojars/production/db_password"
}

data "aws_ssm_parameter" "db_username" {
  name = "/clojars/production/db_user"
}

resource "aws_security_group" "allow_postgres" {
  name        = "allow_postgres2"
  description = "Allow access to postgres server"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.server_production.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.server_production.id]
  }
}

resource "aws_db_subnet_group" "production" {
  name        = "clojars-production"
  description = "Private subnets for the production database"
  subnet_ids  = values(aws_subnet.database)[*].id
}

resource "aws_db_instance" "production" {
  allocated_storage            = 20
  backup_retention_period      = 7
  db_subnet_group_name         = aws_db_subnet_group.production.name
  deletion_protection          = true
  engine                       = "postgres"
  engine_version               = "18.4"
  identifier                   = "clojars-production2"
  instance_class               = "db.t4g.small"
  db_name                      = "clojars"
  password                     = data.aws_ssm_parameter.db_password.value
  publicly_accessible          = false
  performance_insights_enabled = true
  storage_type                 = "gp2"
  username                     = data.aws_ssm_parameter.db_username.value
  vpc_security_group_ids       = [aws_security_group.allow_postgres.id]
}
