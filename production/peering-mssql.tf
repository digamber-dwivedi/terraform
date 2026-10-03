# Bridge from the new production VPC to the old account's MSSQL (gadiyadekho-db).
# TEMPORARY: delete this file once account and newvehicle run on PostgreSQL.

provider "aws" {
  alias   = "old"
  region  = "ap-south-1"
  profile = "old-gadiyahub"
}

locals {
  old_account_id     = "109024386163"
  old_vpc_id         = "vpc-0b0d264df495fbae2"
  old_vpc_cidr       = "172.31.0.0/16"
  old_route_table_id = "rtb-04f2b57b60ec84c67"
  old_mssql_sg_id    = "sg-027689b301417e7b5"
}

resource "aws_vpc_peering_connection" "mssql" {
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = local.old_vpc_id
  peer_owner_id = local.old_account_id
  peer_region   = "ap-south-1"
  auto_accept   = false
  tags          = { Name = "${var.project}-to-old-mssql", Side = "requester" }
}

resource "aws_vpc_peering_connection_accepter" "mssql" {
  provider                  = aws.old
  vpc_peering_connection_id = aws_vpc_peering_connection.mssql.id
  auto_accept               = true
  tags                      = { Name = "gadiyahub-production-to-old-mssql", Side = "accepter" }
}

# The RDS endpoint is public. Without this, the new VPC resolves it to the public IP
# and traffic goes over the internet instead of the peering.
resource "aws_vpc_peering_connection_options" "mssql_accepter" {
  provider                  = aws.old
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.mssql.id
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "new_to_old_mssql" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = local.old_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.mssql.id
  depends_on                = [aws_vpc_peering_connection_accepter.mssql]
}

resource "aws_route" "old_to_new" {
  provider                  = aws.old
  route_table_id            = local.old_route_table_id
  destination_cidr_block    = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.mssql.id
  depends_on                = [aws_vpc_peering_connection_accepter.mssql]
}

resource "aws_security_group_rule" "old_mssql_from_new" {
  provider          = aws.old
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = local.old_mssql_sg_id
  description       = "MSSQL from gadiyahub new production VPC via peering"
}
