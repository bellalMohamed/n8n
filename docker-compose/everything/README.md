# n8n Everything Setup

This is a comprehensive n8n setup that includes:
- **PostgreSQL** as the database
- **Redis** for queue management
- **n8n Worker** for background job processing
- **Caddy** as a reverse proxy with automatic SSL
- **n8n Main Instance** for the web interface

## Features

- **Scalable Architecture**: Separate worker containers for background processing
- **Production Ready**: PostgreSQL database with proper health checks
- **Queue Management**: Redis-based job queue for reliable execution
- **SSL/TLS**: Automatic HTTPS with Caddy reverse proxy
- **Health Monitoring**: Built-in health checks for all services
- **Data Persistence**: Volumes for database, n8n data, and Caddy certificates

## Prerequisites

- Docker and Docker Compose installed
- Domain name configured (for SSL certificates)
- Basic understanding of Docker and n8n

## Quick Start

1. **Clone and navigate to this directory:**
   ```bash
   cd docker-compose/everything
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   ```

3. **Configure your environment variables in `.env`:**
   ```bash
   # Database Configuration
   POSTGRES_USER=n8n
   POSTGRES_PASSWORD=your_secure_password
   POSTGRES_DB=n8n
   POSTGRES_NON_ROOT_USER=n8n_user
   POSTGRES_NON_ROOT_PASSWORD=your_user_password
   
   # n8n Configuration
   ENCRYPTION_KEY=your_32_character_encryption_key
   GENERIC_TIMEZONE=UTC
   
   # Domain Configuration
   SUBDOMAIN=n8n
   DOMAIN_NAME=yourdomain.com
   
   # Data Paths
   DATA_FOLDER=./data
   ```

4. **Create necessary directories:**
   ```bash
   mkdir -p data/caddy_config data/local_files
   ```

5. **Start the services:**
   ```bash
   docker-compose up -d
   ```

6. **Access n8n:**
   - Main instance: `https://n8n.yourdomain.com`
   - Direct access: `http://localhost:5678`

## Services

### PostgreSQL (Database)
- **Port**: Internal only (5432)
- **Volume**: `db_storage`
- **Health Check**: Automatic with pg_isready

### Redis (Queue)
- **Port**: Internal only (6379)
- **Volume**: `redis_storage`
- **Health Check**: Automatic with redis-cli ping

### Caddy (Reverse Proxy)
- **Ports**: 80 (HTTP), 443 (HTTPS)
- **Volume**: `caddy_data` for certificates
- **Features**: Automatic SSL, reverse proxy to n8n

### n8n (Main Instance)
- **Port**: 5678 (also accessible via Caddy)
- **Volume**: `n8n_storage`
- **Features**: Web interface, workflow management

### n8n Worker
- **Port**: Internal only
- **Features**: Background job processing
- **Dependencies**: Requires main n8n instance

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `POSTGRES_USER` | PostgreSQL root user | Yes |
| `POSTGRES_PASSWORD` | PostgreSQL root password | Yes |
| `POSTGRES_DB` | Database name | Yes |
| `POSTGRES_NON_ROOT_USER` | n8n database user | Yes |
| `POSTGRES_NON_ROOT_PASSWORD` | n8n database password | Yes |
| `ENCRYPTION_KEY` | 32-character encryption key | Yes |
| `SUBDOMAIN` | Subdomain for n8n | Yes |
| `DOMAIN_NAME` | Your domain name | Yes |
| `GENERIC_TIMEZONE` | Timezone for n8n | Yes |
| `DATA_FOLDER` | Path to data directory | Yes |

### Caddy Configuration

The Caddyfile is located at `data/caddy_config/Caddyfile`. You can modify it to:
- Add custom domains
- Configure additional routes
- Set up custom SSL certificates
- Add authentication

## Management Commands

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f n8n
docker-compose logs -f n8n-worker
docker-compose logs -f postgres
docker-compose logs -f redis
docker-compose logs -f caddy
```

### Restart Services
```bash
# All services
docker-compose restart

# Specific service
docker-compose restart n8n
```

### Update Services
```bash
docker-compose pull
docker-compose up -d
```

## Troubleshooting

### Database Connection Issues
1. Check if PostgreSQL is healthy: `docker-compose ps postgres`
2. Verify environment variables are set correctly
3. Check logs: `docker-compose logs postgres`

### Worker Not Processing Jobs
1. Ensure Redis is running: `docker-compose ps redis`
2. Check worker logs: `docker-compose logs n8n-worker`
3. Verify queue configuration in environment variables

### SSL Certificate Issues
1. Check Caddy logs: `docker-compose logs caddy`
2. Verify domain configuration in `.env`
3. Ensure ports 80 and 443 are accessible

### Data Persistence
All data is stored in Docker volumes:
- `db_storage`: PostgreSQL data
- `n8n_storage`: n8n workflows and data
- `redis_storage`: Redis data
- `caddy_data`: SSL certificates

## Security Considerations

1. **Change default passwords** in the `.env` file
2. **Use strong encryption keys** (32 characters minimum)
3. **Configure firewall** to only expose necessary ports
4. **Regular updates** of Docker images
5. **Backup volumes** regularly
6. **Monitor logs** for suspicious activity

## Scaling

To scale the worker instances:
```bash
docker-compose up -d --scale n8n-worker=3
```

This will create 3 worker instances for better job processing performance.

## Support

For issues and questions:
- Check the [n8n documentation](https://docs.n8n.io/)
- Visit the [n8n community forums](https://community.n8n.io/)
- Review Docker and Caddy documentation 