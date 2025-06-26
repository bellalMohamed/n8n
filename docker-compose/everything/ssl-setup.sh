#!/bin/bash

# SSL Certificate Setup Script for Nginx
# This script helps you set up SSL certificates for zealautomations.cloud

set -e

echo "🔒 SSL Certificate Setup for zealautomations.cloud"
echo "=================================================="

# Check if certbot is available
if ! command -v certbot &> /dev/null; then
    echo "❌ Certbot is not installed. Installing..."
    sudo apt update
    sudo apt install -y certbot
fi

# Create SSL directory
echo "📁 Creating SSL directory..."
mkdir -p data/nginx/ssl

# Function to generate self-signed certificate for testing
generate_self_signed() {
    echo "🔧 Generating self-signed certificate for testing..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout data/nginx/ssl/key.pem \
        -out data/nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=zealautomations.cloud"
    
    echo "✅ Self-signed certificate generated"
    echo "⚠️  This is for testing only. Use Let's Encrypt for production."
}

# Function to obtain Let's Encrypt certificate
obtain_lets_encrypt() {
    echo "🌐 Obtaining Let's Encrypt certificate..."
    
    # Stop nginx temporarily
    docker-compose stop nginx
    
    # Obtain certificate
    sudo certbot certonly --standalone \
        --email your-email@example.com \
        --agree-tos \
        --no-eff-email \
        -d zealautomations.cloud
    
    # Copy certificates to nginx directory
    sudo cp /etc/letsencrypt/live/zealautomations.cloud/fullchain.pem data/nginx/ssl/cert.pem
    sudo cp /etc/letsencrypt/live/zealautomations.cloud/privkey.pem data/nginx/ssl/key.pem
    
    # Set proper permissions
    sudo chown -R $USER:$USER data/nginx/ssl/
    chmod 600 data/nginx/ssl/key.pem
    chmod 644 data/nginx/ssl/cert.pem
    
    # Start nginx
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
echo "1) Generate self-signed certificate (for testing)"
echo "2) Obtain Let's Encrypt certificate (for production)"
echo "3) Renew existing certificates"
echo "4) Exit"
echo ""

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        generate_self_signed
        ;;
    2)
        read -p "Enter your email address: " email
        sed -i "s/your-email@example.com/$email/" "$0"
        obtain_lets_encrypt
        ;;
    3)
        renew_certificates
        ;;
    4)
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
echo "1. If you used self-signed certificate, you'll see security warnings in browsers"
echo "2. If you used Let's Encrypt, your site will have valid SSL certificates"
echo "3. Set up automatic renewal with: sudo crontab -e"
echo "   Add: 0 12 * * * /path/to/your/project/ssl-setup.sh renew"
echo ""
echo "Access your n8n instance at: https://zealautomations.cloud" 