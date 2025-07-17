resource "aws_instance" "proxy_server" {
  depends_on      = [var.key]
  ami             = var.img
  instance_type   = "t3.micro"
  security_groups = var.sg
  subnet_id       = var.subnet
  key_name        = var.key

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/.ssh/project-key")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras enable nginx1",
      "sudo yum install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "sudo bash -c 'cat > /etc/nginx/conf.d/reverse-proxy.conf <<EOT\nserver {\n    listen 80;\n    location / {\n        proxy_pass http://${var.backend_ip}/;\n        proxy_set_header Host \\$host;\n        proxy_set_header X-Real-IP \\$remote_addr;\n        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;\n        proxy_set_header X-Forwarded-Proto \\$scheme;\n    }\n}\nEOT'",
      "sudo nginx -t",
      "sudo systemctl reload nginx"
    ]
  }
}
