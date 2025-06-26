#!/bin/bash

# n8n Everything Setup Script
# This script helps you set up the n8n everything configuration

set -e

echo "🚀 n8n Everything Setup"
echo "========================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp env.example .env
    echo "⚠️  Please edit .env file with your configuration before starting services"
    echo "   Important: Change all passwords and set your domain name!"
else
    echo "✅ .env file already exists"
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p data/caddy_config data/local_files

# Copy Caddyfile if it doesn't exist
if [ ! -f data/caddy_config/Caddyfile ]; then
    echo "📄 Creating Caddyfile..."
    cat > data/caddy_config/Caddyfile << 'EOF'
n8n.local.server {
    tls internal
    reverse_proxy n8n:5678 {
        flush_interval -1
    }
}
EOF
    echo "⚠️  Please update the Caddyfile with your actual domain name"
fi

# Make init-data.sh executable
chmod +x init-data.sh

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Update data/caddy_config/Caddyfile with your domain"
echo "3. Run: docker-compose up -d"
echo "4. Access n8n at: https://your-domain.com (after DNS setup)"
echo ""
echo "For more information, see README.md" 