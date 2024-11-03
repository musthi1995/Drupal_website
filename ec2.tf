# EC2 Instance
resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main_subnet.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]  # Use security group ID
  associate_public_ip_address = true  # Ensure public IP is assigned
  
  # User data script for LAMP and Drupal setup
  user_data = <<-EOF
    #!/bin/bash
    apt update && apt upgrade -y
    apt install -y apache2 mysql-server php libapache2-mod-php php-mysql php-xml php-gd php-mbstring php-curl php-zip php-json

    systemctl start apache2
    systemctl enable apache2

    mysql -e "CREATE DATABASE drupaldb;"
    mysql -e "CREATE USER 'drupal_mm'@'localhost' IDENTIFIED BY 'mypassword';"
    mysql -e "GRANT ALL PRIVILEGES ON drupaldb.* TO 'drupal_mm'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

    mkdir -p /var/www/html/drupal
    curl -sSL https://www.drupal.org/download-latest/tar.gz | tar -xz -C /var/www/html/drupal --strip-components=1

    chown -R www-data:www-data /var/www/html/drupal
    chmod -R 755 /var/www/html/drupal

    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

    EC2_PUBLIC_DNS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-hostname)


    cat > /etc/apache2/sites-available/drupal.conf <<-APACHE
    <VirtualHost *:80>
        ServerAdmin admin@example.com
        DocumentRoot /var/www/html/drupal
        ServerName $(EC2_PUBLIC_DNS) 

        <Directory /var/www/html/drupal>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog /var/log/apache2/error.log 
      CustomLog /var/log/apache2/access.log combined 
    </VirtualHost>
    APACHE

    a2ensite drupal.conf
    a2enmod rewrite
    systemctl restart apache2
  EOF

  tags = {
    Name = "Drupal-Server"
  }
}
