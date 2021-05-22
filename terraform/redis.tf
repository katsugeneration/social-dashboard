resource "aws_elasticache_subnet_group" "sg_redash_ec" {
  name = "sg-redash-ec"
  subnet_ids = [
    aws_subnet.social_dashboard_subnet_private_a.id,
    aws_subnet.social_dashboard_subnet_private_c.id
  ]
}

resource "aws_elasticache_parameter_group" "redis_redash_ec" {
  name   = "redis-redash-ec"
  family = "redis6.x"
}

resource "aws_elasticache_cluster" "redash_ec" {
  cluster_id           = "redash-ec"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  engine_version       = "6.x"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.redis_redash_ec.name
  subnet_group_name    = aws_elasticache_subnet_group.sg_redash_ec.name
  security_group_ids = [
    aws_security_group.ec_redash_sg.id
  ]
}