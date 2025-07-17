resource "aws_instance" "backend" {
  depends_on      = [ var.key ]
  ami             = var.img
  instance_type   = "t3.micro"
  security_groups = var.sg
  subnet_id       = var.subnet
  key_name        = var.key

  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable httpd
systemctl start httpd

cat <<EOT > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>My Web Server</title>
</head>
<body>
    <h1>Hello from Apache!</h1>
    <p>This server is up and running 🚀</p>
    <p>Hostname: $(hostname)</p>
</body>
</html>
EOT
EOF
}
