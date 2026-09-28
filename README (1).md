# Terraform: AWS VGW <-> OCI DRG Site-to-Site VPN

IaC version of MANUAL-SETUP.md. Builds both clouds, the IPsec tunnel, and a test VM on each side.
Every fix from the manual build is baked in: DH group 14 on both phases, AES-CBC + HMAC-SHA2-256-128
on OCI phase 2, default DRG route tables, VMs explicitly placed in the VPN VPC/VCN, firewalld disabled.

## Usage
```
cp terraform.tfvars.example terraform.tfvars   # fill in compartment OCID, ssh key, your IP
aws configure                                   # AWS creds
oci setup config                                # OCI creds (~/.oci/config), if not done
./apply.sh                                      # runs both phases
```
Wait 3-5 minutes, then SSH into each VM and use the `ping_*` commands printed in the outputs.

## Why two phases?
AWS needs OCI's tunnel IP (Customer Gateway) and OCI needs AWS's tunnel IP (CPE): a circular dependency.
Phase 1 uses placeholder CGW `1.1.1.1`; phase 2 swaps in the real IP. `apply.sh` checks that the VPN
connection is updated in place. If Terraform ever wants to *replace* it, AWS would assign new IPs and
the OCI CPE would break, so the script aborts.

## Notes
- Terraform state contains the pre-shared key: keep `terraform.tfstate` private (use a remote encrypted backend for real use).
- Lab setup: 1 tunnel, static routing, SSH restricted to `my_ip_cidr`. Production: 2 tunnels + BGP.
- Always Free OCI VM: set `oci_shape = "VM.Standard.E2.1.Micro"` (if available in your region/AD).
- Destroy everything: `terraform destroy -var "oci_tunnel_public_ip=$(terraform output -raw oci_tunnel_public_ip)"`
