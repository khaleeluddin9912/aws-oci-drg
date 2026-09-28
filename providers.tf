terraform {
  required_version = ">= 1.5"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.60" }
    oci    = { source = "oracle/oci", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region = var.aws_region
}

# Reads ~/.oci/config [DEFAULT] (or OCI_* env vars). Region set here.
provider "oci" {
  region = var.oci_region
}
