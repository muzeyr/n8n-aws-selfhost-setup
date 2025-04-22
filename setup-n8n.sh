#!/bin/bash

echo "🔧 Welcome to the n8n AWS Self-Hosting Auto Installer"

# Ask user for their domain
read -p "Please enter your domain name (e.g., n8n.example.com): " USER_DOMAIN

if [[ -z "$USER_DOMAIN" ]]; then
  echo "❌ Error: No domain entered. Exiting."
  exit 1
fi

echo "🌐 Domain set to: $USER_DOMAIN"

# Update system and install required packages
echo "🚀 Updating system and installing necessary tools..."
sudo yum update -y
sudo yum install -y nginx docker certbot python3-certbot-nginx

# Start and enable services
echo "🔧 Starting and enabling Nginx and Docker services..."
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to the docker group
echo "👤 Adding EC2 user to Docker group..."
sudo usermod -aG docker ec2-user

# Create Nginx config file for n8n
echo "📁 Creating Nginx configuration..."
NGINX_CONF_PATH="/etc/nginx/conf.d/n8n.conf"
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

# Test and restart Nginx
echo "🔄 Testing and restarting Nginx..."
sudo nginx -t && sudo systemctl restart nginx

# Generate SSL certificate
echo "🔐 Generating SSL certificate with Certbot..."
sudo certbot --nginx -d $USER_DOMAIN

# Schedule auto-renewal for SSL certificate
echo "📆 Adding cron job for certificate auto-renewal..."
echo "0 0 * * * certbot renew --quiet" | sudo tee -a /etc/crontab > /dev/null

# Pull the latest n8n Docker image
echo "⬇️ Pulling latest n8n Docker image..."
docker pull n8nio/n8n:latest

# Prepare .n8n folder and permissions
echo "📂 Preparing ~/.n8n folder and setting permissions..."
mkdir -p ~/.n8n
sudo chown -R ec2-user:docker ~/.n8n
sudo chmod -R 777 ~/.n8n

# Stop and remove any existing container
docker stop n8n 2>/dev/null
docker rm n8n 2>/dev/null

# Run n8n container with environment variables
echo "🐳 Running n8n Docker container..."
docker run -d --name n8n -p 5678:5678 \
-v ~/.n8n:/home/node/.n8n \
-e N8N_PROTOCOL=https \
-e N8N_HOST=$USER_DOMAIN \
-e N8N_PORT=5678 \
-e BASE_URL=https://$USER_DOMAIN \
-e WEBHOOK_URL=https://$USER_DOMAIN \
-e WEBHOOK_TUNNEL_URL=https://$USER_DOMAIN \
-e VUE_APP_URL_BASE_API=https://$USER_DOMAIN \
-e WEBHOOK_INCLUDE_ORIGIN_HEADER_DATA=false \
-e N8N_EDITOR_BASE_URL=https://$USER_DOMAIN \
-e N8N_ENABLE_COMMUNITY_NODES=true \
-e NODE_FUNCTION_ALLOW_EXTERNAL=* \
-e N8N_CUSTOM_EXTENSIONS=/home/node/.n8n/custom \
-e N8N_IGNORE_CERT_ERRORS=true \
-e N8N_SECURE_COOKIE=false \
n8nio/n8n

echo "✅ Done! You can now access your n8n instance at: https://$USER_DOMAIN 🚀"
