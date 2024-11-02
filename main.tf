provider "aws" {
  region = var.aws_region
}

# VPC and Subnet
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  }

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true  # Allow public IP assignment
}

# Internet Gateway
resource "aws_internet_gateway" "main_gateway" {
  vpc_id = aws_vpc.main_vpc.id
}

# Route Table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  # Allow all outbound traffic to the internet
    gateway_id = aws_internet_gateway.main_gateway.id
  }
}

# Route Table Association
resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

# Security Group
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_sg"
  }
}

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