# Docker Setup Guide

This guide explains how to use Docker with the Agendog monorepo for both development and production environments.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Available Scripts](#available-scripts)
- [Services](#services)
- [Profiles](#profiles)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)

## 🚀 Quick Start

### Development Mode (with hot reload)

```bash
# Start development environment
pnpm docker:dev

# Or with rebuild
pnpm docker:dev:build
```

This will start:

- ✅ Next.js app with hot reload on `http://localhost:3000`
- ✅ PostgreSQL database on `localhost:5432`
- ✅ pgAdmin on `http://localhost:5050`

### Production Mode

```bash
# Build and start production environment
pnpm docker:prod:build

# Or just start (if already built)
pnpm docker:prod
```

This will start:

- ✅ Next.js app (optimized build) on `http://localhost:3000`
- ✅ PostgreSQL database on `localhost:5432`

## 📜 Available Scripts

### Development Scripts

| Script       | Description                                |
| ------------ | ------------------------------------------ |
| `pnpm dev`   | Run Next.js dev server locally (no Docker) |
| `pnpm build` | Build Next.js app locally                  |
| `pnpm start` | Start Next.js production server locally    |

### Docker Development Scripts

| Script                  | Description                           |
| ----------------------- | ------------------------------------- |
| `pnpm docker:dev`       | Start dev environment with hot reload |
| `pnpm docker:dev:build` | Rebuild and start dev environment     |
| `pnpm docker:dev:down`  | Stop dev environment                  |

### Docker Production Scripts

| Script                   | Description                           |
| ------------------------ | ------------------------------------- |
| `pnpm docker:prod`       | Start production environment          |
| `pnpm docker:prod:build` | Build and start production (detached) |
| `pnpm docker:prod:down`  | Stop production environment           |

### Docker Utility Scripts

| Script                 | Description                                           |
| ---------------------- | ----------------------------------------------------- |
| `pnpm docker:stop`     | Stop all Docker services                              |
| `pnpm docker:clean`    | Stop and remove all containers, volumes, and networks |
| `pnpm docker:logs`     | View logs from all services                           |
| `pnpm docker:logs:app` | View logs from web-app only                           |
| `pnpm docker:logs:db`  | View logs from database only                          |

### Database Scripts

| Script          | Description                          |
| --------------- | ------------------------------------ |
| `pnpm db:start` | Start only the database              |
| `pnpm db:stop`  | Stop the database                    |
| `pnpm db:reset` | Reset database (⚠️ deletes all data) |
| `pnpm db:shell` | Open PostgreSQL shell                |
| `pnpm pgadmin`  | Start pgAdmin UI                     |

## 🔧 Services

### Web App (Development)

- **Container**: `agendog-web-app-dev`
- **Port**: `3000`
- **Features**:
  - Hot reload enabled
  - Source code mounted as volumes
  - Automatic dependency installation

### Web App (Production)

- **Container**: `agendog-web-app`
- **Port**: `3000`
- **Features**:
  - Optimized build
  - Standalone mode
  - Multi-stage Docker build

### PostgreSQL Database

- **Container**: `agendog-db`
- **Port**: `5432`
- **Credentials**:
  - User: `postgres`
  - Password: `postgres`
  - Database: `agendog`
- **Volume**: `db-data` (persists data between restarts)

### pgAdmin (Development Only)

- **Container**: `agendog-pgadmin`
- **Port**: `5050`
- **URL**: `http://localhost:5050`
- **Credentials**:
  - Email: `admin@agendog.local`
  - Password: `admin`

#### Connecting to Database in pgAdmin

1. Open `http://localhost:5050`
2. Login with credentials above
3. Add new server:
   - **Name**: Agendog Local
   - **Host**: `db` (not localhost!)
   - **Port**: `5432`
   - **Username**: `postgres`
   - **Password**: `postgres`

## 🎯 Profiles

Docker Compose uses profiles to separate development and production environments:

### Development Profile

Includes:

- `web-app-dev` (with hot reload)
- `db` (PostgreSQL)
- `pgadmin` (Database UI)

### Production Profile

Includes:

- `web-app` (optimized build)
- `db` (PostgreSQL)

## 🌍 Environment Variables

### Default Variables (in compose.yaml)

```env
NODE_ENV=production|development
DATABASE_URL=postgresql://postgres:postgres@db:5432/agendog
NEXT_PUBLIC_API_URL=http://localhost:3000
```

### Custom Environment Variables

Create a `.env` file in the root directory:

```env
# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=agendog

# Next.js
NEXT_PUBLIC_API_URL=http://localhost:3000
DATABASE_URL=postgresql://postgres:your_secure_password@db:5432/agendog

# Add your custom variables here
NEXT_PUBLIC_CUSTOM_VAR=value
```

Then update `compose.yaml` to use `env_file`:

```yaml
services:
  web-app:
    env_file:
      - .env
```

## 🐛 Troubleshooting

### Port Already in Use

If you get "port already in use" errors:

```bash
# Check what's using the port
lsof -i :3000  # or :5432, :5050

# Stop all Docker containers
pnpm docker:stop

# Or kill the specific process
kill -9 <PID>
```

### Database Connection Issues

```bash
# Check if database is healthy
docker compose ps

# View database logs
pnpm docker:logs:db

# Reset database
pnpm db:reset
```

### Hot Reload Not Working (Development)

```bash
# Rebuild the development environment
pnpm docker:dev:down
pnpm docker:dev:build
```

### Clean Slate

If everything is broken, start fresh:

```bash
# Remove all containers, volumes, and networks
pnpm docker:clean

# Remove Docker images
docker rmi agendog-web-app:latest

# Start fresh
pnpm docker:dev:build
```

### Permission Issues (Linux/WSL)

If you encounter permission issues with volumes:

```bash
# Fix ownership
sudo chown -R $USER:$USER node_modules apps/web-app/node_modules
```

## 📦 Volume Management

### List Volumes

```bash
docker volume ls | grep agendog
```

### Inspect Volume

```bash
docker volume inspect agendog_db-data
```

### Remove Specific Volume

```bash
docker volume rm agendog_db-data
```

## 🔍 Useful Commands

### Execute Commands in Running Container

```bash
# Web app container
docker compose exec web-app sh

# Database container
docker compose exec db sh

# Run pnpm command in web-app
docker compose exec web-app pnpm --filter web-app build
```

### View Resource Usage

```bash
docker stats
```

### Prune Unused Resources

```bash
# Remove unused containers, networks, images
docker system prune -a

# Remove unused volumes
docker volume prune
```

## 🎓 Best Practices

1. **Development**: Always use `pnpm docker:dev` for local development with hot reload
2. **Production Testing**: Use `pnpm docker:prod:build` to test production builds locally
3. **Database**: Use `pnpm db:start` if you only need the database running
4. **Logs**: Use `pnpm docker:logs:app` to debug application issues
5. **Clean Up**: Run `pnpm docker:clean` periodically to free up disk space

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Next.js Docker Documentation](https://nextjs.org/docs/deployment#docker-image)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
