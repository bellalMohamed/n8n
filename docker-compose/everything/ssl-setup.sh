#!/bin/bash

# SSL Certificate Setup Script for Nginx with Let's Encrypt
# This script helps you set up SSL certificates for zealautomations.cloud

set -e

echo "🔒 Let's Encrypt SSL Certificate Setup for zealautomations.cloud"
echo "================================================================"

# Check if certbot is available
if ! command -v certbot &> /dev/null; then
    echo "❌ Certbot is not installed. Installing..."
    sudo apt update
    sudo apt install -y certbot
fi

# Create SSL directory
echo "📁 Creating SSL directory..."
mkdir -p data/nginx/ssl

# Function to obtain Let's Encrypt certificate
obtain_lets_encrypt() {
    echo "🌐 Obtaining Let's Encrypt certificate..."
    
    # Ensure SSL directory exists
    mkdir -p data/nginx/ssl
    
    # Stop nginx temporarily
    echo "🛑 Stopping Nginx container for certificate generation..."
    docker-compose stop nginx
    
    # Obtain certificate
    echo "🔐 Running certbot to obtain certificate..."
    sudo certbot certonly --standalone \
        --email b.mohamed@getzeal.io \
        --agree-tos \
        --no-eff-email \
        -d zealautomations.cloud
    
    # Verify certificates were obtained
    if [ ! -f /etc/letsencrypt/live/zealautomations.cloud/fullchain.pem ] || [ ! -f /etc/letsencrypt/live/zealautomations.cloud/privkey.pem ]; then
        echo "❌ Failed to obtain Let's Encrypt certificates"
        echo "🔄 Starting Nginx with HTTP-only configuration..."
        docker-compose up -d nginx
        exit 1
    fi
    
    # Copy certificates to nginx directory
    echo "📋 Copying certificates to Nginx directory..."
    sudo cp /etc/letsencrypt/live/zealautomations.cloud/fullchain.pem data/nginx/ssl/cert.pem
    sudo cp /etc/letsencrypt/live/zealautomations.cloud/privkey.pem data/nginx/ssl/key.pem
    
    # Set proper permissions
    sudo chown -R $USER:$USER data/nginx/ssl/
    chmod 600 data/nginx/ssl/key.pem
    chmod 644 data/nginx/ssl/cert.pem
    
    # Verify certificates exist in the right place
    if [ ! -f data/nginx/ssl/cert.pem ] || [ ! -f data/nginx/ssl/key.pem ]; then
        echo "❌ Failed to copy certificates to Nginx directory"
        echo "🔄 Starting Nginx with HTTP-only configuration..."
        docker-compose up -d nginx
        exit 1
    fi
    
    echo "✅ Let's Encrypt certificates obtained and copied successfully"
    
    # Update Nginx configuration with full SSL setup
    echo "📝 Updating Nginx configuration with SSL..."
    cat > data/nginx/conf.d/zealautomations.cloud.conf << 'EOF'
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name zealautomations.cloud;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl;
    http2 on;
    server_name zealautomations.cloud;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-ancestors 'self';" always;
    
    # Rate limiting for API endpoints
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://n8n:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Rate limiting for login
    location /login {
        limit_req zone=login burst=5 nodelay;
        proxy_pass http://n8n:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
    }
    
    # Main application
    location / {
        proxy_pass http://n8n:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
    
    # Start nginx
    echo "🚀 Starting Nginx container with SSL configuration..."
    docker-compose up -d nginx
    
    echo "✅ Let's Encrypt certificate obtained and installed"
}

# Function to renew certificates
renew_certificates() {
    echo "🔄 Renewing certificates..."
    
    # Stop nginx temporarily
    docker-compose stop nginx
    
    # Renew certificates
    sudo certbot renew
    
    # Copy renewed certificates
    sudo cp /etc/letsencrypt/live/zealautomations.cloud/fullchain.pem data/nginx/ssl/cert.pem
    sudo cp /etc/letsencrypt/live/zealautomations.cloud/privkey.pem data/nginx/ssl/key.pem
    
    # Set proper permissions
    sudo chown -R $USER:$USER data/nginx/ssl/
    chmod 600 data/nginx/ssl/key.pem
    chmod 644 data/nginx/ssl/cert.pem
    
    # Start nginx
    docker-compose up -d nginx
    
    echo "✅ Certificates renewed"
}

# Main menu
echo ""
echo "Choose an option:"
echo "1) Obtain Let's Encrypt certificate (for production)"
echo "2) Renew existing certificates"
echo "3) Exit"
echo ""

read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        obtain_lets_encrypt
        ;;
    2)
        renew_certificates
        ;;
    3)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac

echo ""
echo "🎉 SSL setup complete!"
echo ""
echo "Next steps:"
echo "1. Your site now has valid SSL certificates from Let's Encrypt"
echo "2. Set up automatic renewal with: sudo crontab -e"
echo "   Add: 0 12 * * * /path/to/your/project/ssl-setup.sh renew"
echo ""
echo "Access your n8n instance at: https://zealautomations.cloud" 