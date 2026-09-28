variable "aws_region" {
  type    = string
  default = "ap-south-2"
}

variable "oci_region" {
  type    = string
  default = "ap-hyderabad-1"
}

variable "oci_compartment_ocid" {
  type        = string
  description = "OCID of the compartment (e.g. cmp-network) for all OCI resources"
}

variable "ssh_public_key" {
  type        = string
  description = "Contents of your SSH public key, e.g. output of: cat ~/.ssh/id_rsa.pub"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your public IP as /32 for SSH, e.g. 103.48.70.59/32"
}

variable "aws_vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "aws_subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "oci_vcn_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "oci_subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "aws_instance_type" {
  type    = string
  default = "t3.micro"
}

# Use "VM.Standard.E2.1.Micro" for Always Free (no shape_config is applied to it)
variable "oci_shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

# PHASE 1: leave empty. PHASE 2: set to output `oci_tunnel_public_ip` (apply.sh does this for you).
variable "oci_tunnel_public_ip" {
  type        = string
  default     = ""
  description = "Oracle VPN headend IP for tunnel 1. Empty on first apply (placeholder CGW 1.1.1.1 is used)."
}
