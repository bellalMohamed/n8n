# Google Cloud Deployment Guide for zealautomations.cloud

This guide will help you deploy the n8n everything setup to Google Cloud Platform.

## Prerequisites

1. **Google Cloud Account** with billing enabled
2. **Domain**: `zealautomations.cloud` (already owned)
3. **Google Cloud CLI** installed locally (optional but recommended)

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable billing for the project

## Step 2: Set up Compute Engine

1. **Enable Compute Engine API:**
   ```bash
   gcloud services enable compute.googleapis.com
   ```

2. **Create a VM instance:**
   ```bash
   gcloud compute instances create n8n-server \
     --zone=us-central1-a \
     --machine-type=e2-standard-2 \
     --image-family=ubuntu-2004-lts \
     --image-project=ubuntu-os-cloud \
     --boot-disk-size=20GB \
     --tags=http-server,https-server
   ```

3. **Create firewall rules:**
   ```bash
   gcloud compute firewall-rules create allow-http \
     --allow tcp:80 \
     --target-tags=http-server \
     --description="Allow HTTP traffic"

   gcloud compute firewall-rules create allow-https \
     --allow tcp:443 \
     --target-tags=https-server \
     --description="Allow HTTPS traffic"
   ```

## Step 3: Connect to Your VM

1. **SSH into your instance:**
   ```bash
   gcloud compute ssh n8n-server --zone=us-central1-a
   ```

2. **Update the system:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

## Step 4: Install Docker and Docker Compose

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again to apply group changes
exit
# SSH back in
gcloud compute ssh n8n-server --zone=us-central1-a
```

## Step 5: Deploy n8n

1. **Clone your repository:**
   ```bash
   git clone <your-repo-url>
   cd n8n-hosting/docker-compose/everything
   ```

2. **Create .env file:**
   ```bash
   cp env.example .env
   nano .env
   ```

3. **Configure .env file with your values:**
   ```bash
   # Database Configuration
   POSTGRES_USER=n8n
   POSTGRES_PASSWORD=your_very_secure_password_here
   POSTGRES_DB=n8n
   POSTGRES_NON_ROOT_USER=n8n_user
   POSTGRES_NON_ROOT_PASSWORD=your_very_secure_user_password_here

   # n8n Configuration
   ENCRYPTION_KEY=your_32_character_encryption_key_here
   GENERIC_TIMEZONE=UTC

   # Domain Configuration
   SUBDOMAIN=
   DOMAIN_NAME=zealautomations.cloud

   # Data Paths
   DATA_FOLDER=./data
   ```

4. **Create necessary directories:**
   ```bash
   mkdir -p data/caddy_config data/local_files
   ```

5. **Make scripts executable:**
   ```bash
   chmod +x init-data.sh setup.sh
   ```

6. **Start the services:**
   ```bash
   docker-compose up -d
   ```

## Step 6: Configure DNS

1. **Get your VM's external IP:**
   ```bash
   gcloud compute instances describe n8n-server --zone=us-central1-a --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
   ```

2. **Configure DNS records:**
   - Go to your domain registrar's DNS settings
   - Add an A record:
     - **Name**: `@` (or leave empty for root domain)
     - **Value**: Your VM's external IP address
     - **TTL**: 300 (or default)

## Step 7: SSL Certificate

Caddy will automatically obtain SSL certificates from Let's Encrypt for `zealautomations.cloud`. The first time you access the site, it may take a few minutes for the certificate to be issued.

## Step 8: Access n8n

Once DNS propagates (can take up to 24 hours, but usually much faster):

- **Production URL**: `https://zealautomations.cloud`
- **Direct access**: `http://YOUR_VM_IP:5678` (for debugging)

## Step 9: Security Considerations

1. **Change default passwords** in the `.env` file
2. **Use strong encryption keys** (32 characters minimum)
3. **Configure Google Cloud firewall** to only allow necessary ports
4. **Set up regular backups** of the Docker volumes
5. **Monitor logs** for suspicious activity

## Step 10: Monitoring and Maintenance

### View logs:
```bash
docker-compose logs -f
```

### Update n8n:
```bash
docker-compose pull
docker-compose up -d
```

### Backup data:
```bash
# Create backup directory
mkdir -p /home/backups

# Backup volumes
docker run --rm -v everything_db_storage:/data -v /home/backups:/backup alpine tar czf /backup/db_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
docker run --rm -v everything_n8n_storage:/data -v /home/backups:/backup alpine tar czf /backup/n8n_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

## Troubleshooting

### Check service status:
```bash
docker-compose ps
```

### Check Caddy logs for SSL issues:
```bash
docker-compose logs caddy
```

### Check n8n logs:
```bash
docker-compose logs n8n
```

### Restart services:
```bash
docker-compose restart
```

## Cost Optimization

- **Use preemptible instances** for development/testing
- **Set up auto-shutdown** for non-production environments
- **Monitor usage** in Google Cloud Console
- **Use appropriate machine types** (e2-standard-2 is good for most use cases)

## Support

For issues:
- Check the [n8n documentation](https://docs.n8n.io/)
- Visit the [n8n community forums](https://community.n8n.io/)
- Review [Google Cloud documentation](https://cloud.google.com/docs/) 