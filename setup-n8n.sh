#!/bin/bash

echo "🔧 Welcome to the n8n AWS Self-Hosting Auto Installer"

# Ask for subdomain (optional)
read -p "Enter your domain name (e.g. n8n.example.com) or leave empty to use IP only: " USER_DOMAIN

# Ask for EC2 Public IP
read -p "Enter your AWS EC2 Public IP address (e.g. 3.121.45.67): " USER_IP

if [[ -z "$USER_IP" ]]; then
  echo "❌ Error: IP address cannot be empty. Exiting."
  exit 1
fi

# Install necessary tools
echo "🚀 Updating system and installing required packages..."
sudo yum update -y
sudo yum install -y nginx docker

# Install SSL tools only if domain is provided
if [[ ! -z "$USER_DOMAIN" ]]; then
  sudo yum install -y certbot python3-certbot-nginx
fi

# Start and enable services
echo "🔧 Starting and enabling Nginx and Docker services..."
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to Docker group
echo "👤 Adding ec2-user to docker group..."
sudo usermod -aG docker ec2-user

# Prepare Nginx config
echo "📁 Creating Nginx configuration..."
NGINX_CONF_PATH="/etc/nginx/conf.d/n8n.conf"

if [[ ! -z "$USER_DOMAIN" ]]; then
  # Domain-based config with HTTPS
  sudo tee $NGINX_CONF_PATH > /dev/null <<EOF
server {
    listen 80;
    server_name $USER_DOMAIN;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect off;
    }
}
EOF
else
  # IP-based config with HTTP only
  sudo tee $NGINX_CONF_PATH > /dev/null <<EOF
server {
    listen 80;
    server_name $USER_IP;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
        proxy_redirect off;
    }
}
EOF
fi

# Restart nginx
sudo nginx -t && sudo systemctl restart nginx

# Setup SSL if domain is provided
if [[ ! -z "$USER_DOMAIN" ]]; then
  echo "🔐 Setting up SSL certificate with Certbot..."
  sudo certbot --nginx -d $USER_DOMAIN

  echo "📆 Adding cron job for auto renewal..."
  echo "0 0 * * * certbot renew --quiet" | sudo tee -a /etc/crontab > /dev/null
fi

# Pull latest n8n image
docker pull n8nio/n8n:latest

# Prepare .n8n folder and permissions
mkdir -p ~/.n8n
sudo chown -R ec2-user:docker ~/.n8n
sudo chmod -R 777 ~/.n8n

# Stop any existing container
docker stop n8n 2>/dev/null
docker rm n8n 2>/dev/null

# Set hostname variable (domain if exists, otherwise IP)
N8N_HOST=${USER_DOMAIN:-$USER_IP}

# Run the container
echo "🐳 Running n8n container..."
docker run -d --name n8n -p 5678:5678 \
-v ~/.n8n:/home/node/.n8n \
-e N8N_PROTOCOL=${USER_DOMAIN:+https} \
-e N8N_HOST=$N8N_HOST \
-e N8N_PORT=5678 \
-e BASE_URL=http://${N8N_HOST} \
-e WEBHOOK_URL=http://${N8N_HOST} \
-e WEBHOOK_TUNNEL_URL=http://${N8N_HOST} \
-e VUE_APP_URL_BASE_API=http://${N8N_HOST} \
-e WEBHOOK_INCLUDE_ORIGIN_HEADER_DATA=false \
-e N8N_EDITOR_BASE_URL=http://${N8N_HOST} \
-e N8N_ENABLE_COMMUNITY_NODES=true \
-e NODE_FUNCTION_ALLOW_EXTERNAL=* \
-e N8N_CUSTOM_EXTENSIONS=/home/node/.n8n/custom \
-e N8N_IGNORE_CERT_ERRORS=true \
-e N8N_SECURE_COOKIE=false \
n8nio/n8n

echo ""
echo "✅ Installation complete!"
echo "🌐 Access your instance at: http://${N8N_HOST}"
[[ ! -z "$USER_DOMAIN" ]] && echo "🔒 If SSL was configured, use: https://${N8N_HOST}"
