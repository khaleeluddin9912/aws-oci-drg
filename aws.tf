locals {
  # Alphanumeric only (OCI rejects . and _), must not start with 0
  psk    = "A${random_string.psk.result}"
  cgw_ip = var.oci_tunnel_public_ip != "" ? var.oci_tunnel_public_ip : "1.1.1.1"
}

resource "random_string" "psk" {
  length  = 32
  special = false
}

data "aws_availability_zones" "az" {
  state = "available"
}

# Latest Ubuntu 22.04 LTS
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# ---------------- Network ----------------
resource "aws_vpc" "this" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  tags                 = { Name = "aws-oci-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "aws-oci-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.aws_subnet_cidr
  availability_zone       = data.aws_availability_zones.az.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "aws-oci-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "aws-oci-rt" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------- VPN: VGW <-> OCI DRG ----------------
resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "aws-oci-vgw" }
}

# Auto-inserts 10.20.0.0/16 -> VGW into the route table once the VPN route exists
resource "aws_vpn_gateway_route_propagation" "public" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = aws_route_table.public.id
}

resource "aws_customer_gateway" "oci" {
  bgp_asn    = 65000 # required by the API, unused with static routing
  ip_address = local.cgw_ip
  type       = "ipsec.1"
  tags       = { Name = var.oci_tunnel_public_ip != "" ? "oci-cgw-real" : "oci-cgw-temp" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpn_connection" "to_oci" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.oci.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags                = { Name = "aws-to-oci-vpn" }

  # Tunnel 1 = the tunnel paired with OCI. Must match oci.tf phase settings exactly.
  tunnel1_preshared_key                = local.psk
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel1_phase1_lifetime_seconds      = 28800
  tunnel1_phase2_lifetime_seconds      = 3600
  tunnel1_dpd_timeout_action           = "restart"
  tunnel1_startup_action               = "start"
}

resource "aws_vpn_connection_route" "oci_cidr" {
  vpn_connection_id      = aws_vpn_connection.to_oci.id
  destination_cidr_block = var.oci_vcn_cidr
}

# ---------------- Test VM ----------------
resource "aws_security_group" "vm" {
  name   = "aws-oci-vm-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  ingress {
    description = "ICMP from OCI VCN"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.oci_vcn_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "aws-oci-vm-sg" }
}

resource "aws_key_pair" "this" {
  key_name   = "aws-oci-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "vm" {
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.public.id # explicit: avoids landing in the default VPC
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.vm.id]
  tags                   = { Name = "aws-vm" }
}
