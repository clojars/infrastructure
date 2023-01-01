data "aws_ssm_parameter" "db_password" {
  name = "/clojars/production/db_password"
}

data "aws_ssm_parameter" "db_username" {
  name = "/clojars/production/db_user"
}

resource "aws_security_group" "allow_postgres" {
  name        = "allow_postgres"
  description = "Allow access tp postgres server" # typo, but can't be changed w/o recreating RDS resource!

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

resource "aws_db_instance" "default" {
  allocated_storage            = 20
  backup_retention_period      = 7
  engine                       = "postgres"
  identifier                   = "clojars-production"
  instance_class               = "db.t3.small"
  db_name                      = "clojars"
  password                     = data.aws_ssm_parameter.db_password.value
  publicly_accessible          = true
  performance_insights_enabled = true
  storage_type                 = "gp2"
  username                     = data.aws_ssm_parameter.db_username.value
  vpc_security_group_ids       = [aws_security_group.allow_postgres.id]
}
