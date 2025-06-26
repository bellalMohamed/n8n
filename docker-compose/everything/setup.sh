#!/bin/bash

# n8n Everything Setup Script (Nginx)
# This script helps you set up the n8n everything configuration with Nginx

set -e

echo "🚀 n8n Everything Setup (Nginx)"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists apt; then
            echo "debian"
        elif command_exists yum; then
            echo "rhel"
        elif command_exists dnf; then
            echo "fedora"
        else
            echo "unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Function to install Docker on Ubuntu/Debian
install_docker_debian() {
    print_status "Installing Docker on Ubuntu/Debian..."
    
    # Update package index
    sudo apt update
    
    # Install prerequisites
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    sudo apt update
    
    # Install Docker
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    print_success "Docker installed successfully"
    print_warning "You need to log out and back in for group changes to take effect"
}

# Function to install Docker on RHEL/CentOS
install_docker_rhel() {
    print_status "Installing Docker on RHEL/CentOS..."
    
    # Install prerequisites
    sudo yum install -y yum-utils
    
    # Add Docker repository
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker
    sudo yum install -y docker-ce docker-ce-cli containerd.io
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    print_success "Docker installed successfully"
    print_warning "You need to log out and back in for group changes to take effect"
}

# Function to install Docker on macOS
install_docker_macos() {
    print_status "Installing Docker on macOS..."
    print_warning "Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop"
    print_warning "After installation, make sure Docker Desktop is running"
    exit 1
}

# Function to install Docker Compose
install_docker_compose() {
    print_status "Installing Docker Compose..."
    
    # Get latest version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    # Download and install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker Compose ${COMPOSE_VERSION} installed successfully"
}

# Function to install additional dependencies
install_dependencies() {
    print_status "Installing additional dependencies..."
    
    OS=$(detect_os)
    
    case $OS in
        "debian")
            sudo apt update
            sudo apt install -y curl wget git openssl certbot
            ;;
        "rhel")
            sudo yum install -y curl wget git openssl certbot
            ;;
        "fedora")
            sudo dnf install -y curl wget git openssl certbot
            ;;
        "macos")
            if command_exists brew; then
                brew install curl wget git openssl
                # Note: certbot installation on macOS might require additional steps
                print_warning "Please install certbot manually if needed for SSL certificates"
            else
                print_warning "Homebrew not found. Please install dependencies manually"
            fi
            ;;
        *)
            print_warning "Unknown OS. Please install dependencies manually: curl, wget, git, openssl, certbot"
            ;;
    esac
    
    print_success "Dependencies installed successfully"
}

# Function to verify Docker installation
verify_docker() {
    print_status "Verifying Docker installation..."
    
    if ! docker --version > /dev/null 2>&1; then
        print_error "Docker is not working properly. Please check the installation."
        exit 1
    fi
    
    if ! docker-compose --version > /dev/null 2>&1; then
        print_error "Docker Compose is not working properly. Please check the installation."
        exit 1
    fi
    
    print_success "Docker and Docker Compose are working properly"
}

# Function to check and install software
check_and_install_software() {
    print_status "Checking system requirements..."
    
    OS=$(detect_os)
    print_status "Detected OS: $OS"
    
    # Check Docker
    if ! command_exists docker; then
        print_warning "Docker not found. Installing..."
        case $OS in
            "debian")
                install_docker_debian
                ;;
            "rhel")
                install_docker_rhel
                ;;
            "macos")
                install_docker_macos
                ;;
            *)
                print_error "Unsupported OS for automatic Docker installation"
                print_warning "Please install Docker manually from https://docs.docker.com/get-docker/"
                exit 1
                ;;
        esac
    else
        print_success "Docker is already installed"
    fi
    
    # Check Docker Compose
    if ! command_exists docker-compose; then
        print_warning "Docker Compose not found. Installing..."
        install_docker_compose
    else
        print_success "Docker Compose is already installed"
    fi
    
    # Install additional dependencies
    install_dependencies
    
    # Verify installations
    verify_docker
}

# Function to check system resources
check_system_resources() {
    print_status "Checking system resources..."
    
    # Check available memory
    if command_exists free; then
        MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
        if [ "$MEMORY_GB" -lt 2 ]; then
            print_warning "Low memory detected: ${MEMORY_GB}GB. n8n recommends at least 2GB RAM"
        else
            print_success "Memory: ${MEMORY_GB}GB (sufficient)"
        fi
    fi
    
    # Check available disk space
    if command_exists df; then
        DISK_GB=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
        if [ "$DISK_GB" -lt 10 ]; then
            print_warning "Low disk space: ${DISK_GB}GB available. n8n recommends at least 10GB"
        else
            print_success "Disk space: ${DISK_GB}GB available (sufficient)"
        fi
    fi
}

# Main setup function
main_setup() {
    # Check and install software
    check_and_install_software
    
    # Check system resources
    check_system_resources
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        print_status "Creating .env file from template..."
        cp env.example .env
        print_warning "Please edit .env file with your configuration before starting services"
        print_warning "Important: Change all passwords and set your domain name!"
    else
        print_success ".env file already exists"
    fi
    
    # Create necessary directories
    print_status "Creating necessary directories..."
    mkdir -p data/nginx/ssl data/local_files
    
    # Create Nginx configuration if it doesn't exist
    if [ ! -f data/nginx/nginx.conf ]; then
        print_status "Creating Nginx main configuration..."
        cat > data/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # Performance optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # Include server configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF
    fi
    
    # Create domain configuration if it doesn't exist
    if [ ! -f data/nginx/conf.d/zealautomations.cloud.conf ]; then
        print_status "Creating Nginx domain configuration..."
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
    listen 443 ssl http2;
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
        print_warning "Please update the domain name in data/nginx/conf.d/zealautomations.cloud.conf if needed"
    fi
    
    # Make init-data.sh executable
    chmod +x init-data.sh
    
    print_success "Setup completed successfully!"
    echo ""
    echo "🎉 Next steps:"
    echo "1. Edit .env file with your configuration"
    echo "2. Update domain name in Nginx config if needed"
    echo "3. Run: ./ssl-setup.sh to set up SSL certificates"
    echo "4. Run: docker-compose up -d to start services"
    echo "5. Access n8n at: https://zealautomations.cloud (after DNS setup)"
    echo ""
    echo "For more information, see README.md and DEPLOYMENT.md"
}

# Run main setup
main_setup 