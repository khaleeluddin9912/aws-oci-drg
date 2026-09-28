#!/usr/bin/env bash
# Runs both phases. Phase 1 creates everything with a placeholder AWS Customer Gateway;
# phase 2 swaps in OCI's real tunnel IP.
set -euo pipefail

terraform init -input=false
echo ">>> PHASE 1: create everything (placeholder Customer Gateway 1.1.1.1)"
terraform apply -auto-approve -input=false

OCI_IP=$(terraform output -raw oci_tunnel_public_ip)
echo ">>> OCI tunnel IP: ${OCI_IP}"

echo ">>> PHASE 2: point AWS Customer Gateway at OCI"
terraform plan -input=false -var "oci_tunnel_public_ip=${OCI_IP}" | tee /tmp/phase2.plan
if grep -q "aws_vpn_connection.to_oci must be replaced" /tmp/phase2.plan; then
  echo "!! VPN connection would be REPLACED (new AWS IPs would break the OCI CPE). Aborting." >&2
  exit 1
fi
terraform apply -auto-approve -input=false -var "oci_tunnel_public_ip=${OCI_IP}"

echo ">>> Done. Wait 3-5 min for the tunnel, then:"
terraform output
