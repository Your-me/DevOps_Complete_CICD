output "instance_public_ip" {
  value     = aws_instance.deploy_server.public_dns
  sensitive = true
}