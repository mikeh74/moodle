# Moodle Docker Setup

This document describes the Docker setup for running Moodle locally using Docker and Docker Compose.

## Overview

The Docker setup provides two environments:
- **Production**: Optimized build with application code baked into the image
- **Development**: Live code mounting for active development with hot-reloading

## Architecture

### Services

1. **moodle** - PHP 8.2 with Apache web server
2. **db** - MySQL 8.0 database

### Docker Files

- `Dockerfile` - Multi-stage build with builder, base, development, and production stages
- `docker-compose.yml` - Production configuration
- `docker-compose.dev.yml` - Development configuration with live code mounting
- `entrypoint.sh` - Container initialization script
- `moodle-php.ini` - Custom PHP configuration for Moodle

## Prerequisites

- Docker Desktop (or Docker Engine + Docker Compose)
- `.env` file with environment variables (see Configuration section)

## Quick Start

### Development Environment

```bash
# Start development environment with live code mounting
docker compose -f docker-compose.dev.yml up -d

# View logs
docker compose -f docker-compose.dev.yml logs -f

# Stop services
docker compose -f docker-compose.dev.yml down
```

The Moodle site will be available at `http://localhost:8080` (or the port specified in `DOCKER_APP_PORT`).

### Production Environment

```bash
# Build and start production environment
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

## Configuration

### Environment Variables

Create a `.env` file in the project root with the following variables:

```env
# Port for accessing Moodle (default: 8080)
DOCKER_APP_PORT=8080

# Add any other Moodle-specific environment variables here
```

### Moodle Configuration

The `config.php` file is mounted into the container at `/var/www/html/config.php`. Ensure your config.php contains the correct database settings:

```php
$CFG->dbtype    = 'mysqli';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'db';  // Service name from docker-compose
$CFG->dbname    = 'moodle';
$CFG->dbuser    = 'moodle';
$CFG->dbpass    = 'moodle';
$CFG->dataroot  = '/var/www/moodledata';
```

## Docker Image Details

### Multi-Stage Build

The Dockerfile uses a multi-stage build strategy for optimization:

1. **Builder Stage**: Compiles PHP extensions with all development dependencies
2. **Base Stage**: Runtime environment with only necessary libraries (no -dev packages)
3. **Development Stage**: Extends base for development use
4. **Production Stage**: Extends base and includes application code

### PHP Extensions

The following PHP extensions are installed:
- gd (image processing)
- zip (file compression)
- xml (XML processing)
- intl (internationalization)
- mbstring (multibyte string support)
- xsl (XSLT processor)
- soap (SOAP protocol)
- pdo, pdo_mysql, mysqli (database connectivity)
- opcache (PHP opcode cache)
- exif (image metadata)
- pcntl (process control)
- redis (Redis support via PECL)

### PHP Configuration

Custom PHP settings are defined in `moodle-php.ini`:

| Setting | Value | Purpose |
|---------|-------|---------|
| `max_execution_time` | 300 | Allows long-running scripts |
| `memory_limit` | 512M | Adequate memory for Moodle |
| `post_max_size` | 100M | Large form submissions |
| `upload_max_filesize` | 100M | File upload limit |
| `max_input_vars` | 5000 | Complex forms support |
| `opcache.enable` | 1 | Improved PHP performance |

## Volumes

### Named Volumes

- `db_data` - Persists MySQL database files
- `moodledata` - Stores Moodle data files (uploads, cache, temp files)

### Development Bind Mounts

In development mode (`docker-compose.dev.yml`):
- `./:/var/www/html` - Mounts the current directory for live code changes
- `./config.php:/var/www/html/config.php` - Mounts configuration file

## Networking

- Moodle service exposes port 80 internally, mapped to `DOCKER_APP_PORT` (default: 8080) on the host
- MySQL service exposes port 3306 for database access from host
- Services communicate via Docker's internal network using service names

## Database

### Connection Details

From the host machine:
- Host: `localhost`
- Port: `3306`
- Database: `moodle`
- User: `moodle`
- Password: `moodle`
- Root Password: `root`

From Moodle container:
- Host: `db` (service name)
- Port: `3306`

### Accessing MySQL

```bash
# Using docker compose
docker compose exec db mysql -u moodle -pmoodle moodle

# Or with root
docker compose exec db mysql -u root -proot
```

## Common Tasks

### Accessing the Moodle Container

```bash
# Development
docker compose -f docker-compose.dev.yml exec moodle bash

# Production
docker compose exec moodle bash
```

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f moodle
docker compose logs -f db
```

### Rebuilding Images

```bash
# Development
docker compose -f docker-compose.dev.yml build --no-cache

# Production
docker compose build --no-cache
```

### Clearing All Data

```bash
# Stop and remove containers, volumes, and networks
docker compose down -v

# This will delete all database data and moodledata!
```

### Running Moodle CLI Commands

```bash
# Example: Run cron
docker compose exec moodle php admin/cli/cron.php

# Example: Purge caches
docker compose exec moodle php admin/cli/purge_caches.php
```

## Troubleshooting

### Permission Issues

If you encounter permission errors with moodledata:

```bash
docker compose exec moodle chown -R www-data:www-data /var/www/moodledata
```

### Database Connection Failed

1. Ensure the database service is running:
   ```bash
   docker compose ps
   ```

2. Check database logs:
   ```bash
   docker compose logs db
   ```

3. Verify config.php has correct database host (`db` not `localhost`)

### Port Already in Use

If port 8080 is already in use, change `DOCKER_APP_PORT` in `.env`:

```env
DOCKER_APP_PORT=8081
```

### Rebuilding After Code Changes (Production)

Production images bake in the code, so rebuild after changes:

```bash
docker compose build
docker compose up -d
```

## Performance Optimization

### OPcache

OPcache is enabled by default for improved PHP performance. Settings can be adjusted in `moodle-php.ini`.

### Redis (Optional)

The Redis PHP extension is installed. To use Redis for session storage or caching, configure it in `config.php` and add a Redis service to `docker-compose.yml`.

## Development vs Production

| Feature | Development | Production |
|---------|-------------|------------|
| Code mounting | Live (bind mount) | Baked into image |
| Image size | Smaller | Larger (includes code) |
| Rebuild needed | No | Yes (after code changes) |
| Hot reload | Yes | No |
| Best for | Active development | Testing/Deployment |

## Security Notes

- Default passwords (`moodle`, `root`) are for development only
- In production, use strong passwords and store them securely
- Consider using Docker secrets for sensitive data
- The database port (3306) is exposed for convenience but should be removed in production

## Additional Resources

- [Moodle Documentation](https://docs.moodle.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
