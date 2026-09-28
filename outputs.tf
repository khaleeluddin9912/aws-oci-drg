output "oci_tunnel_public_ip" {
  description = "Oracle VPN headend IP (tunnel 1). Needed for phase 2."
  value       = data.oci_core_ipsec_connection_tunnels.t.ip_sec_connection_tunnels[0].vpn_ip
}

output "aws_tunnel1_public_ip" {
  value = aws_vpn_connection.to_oci.tunnel1_address
}

output "oci_tunnel_status" {
  description = "Should become UP a few minutes after phase 2"
  value       = data.oci_core_ipsec_connection_tunnels.t.ip_sec_connection_tunnels[0].status
}

output "aws_vm" {
  value = {
    public_ip  = aws_instance.vm.public_ip
    private_ip = aws_instance.vm.private_ip
    ssh        = "ssh -i <key> ubuntu@${aws_instance.vm.public_ip}"
    ping_oci   = "ping -c 4 ${oci_core_instance.vm.private_ip}"
  }
}

output "oci_vm" {
  value = {
    public_ip  = oci_core_instance.vm.public_ip
    private_ip = oci_core_instance.vm.private_ip
    ssh        = "ssh -i <key> opc@${oci_core_instance.vm.public_ip}"
    ping_aws   = "ping -c 4 ${aws_instance.vm.private_ip}"
  }
}
