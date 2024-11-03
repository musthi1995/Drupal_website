output "ec2_public_ip" {
  value = aws_instance.web_server.public_ip
  description = "Public IP of the Drupal EC2 instance"
}

output "ec2_public_dns" {
  value = aws_instance.web_server.public_dns
  description = "Public DNS of the Drupal EC2 instance"
}
