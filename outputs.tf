output "ubuntu_ips" {
  value = aws_instance.ubuntu[*].public_ip
}

output "redhat_ips" {
  value = aws_instance.redhat[*].public_ip
}