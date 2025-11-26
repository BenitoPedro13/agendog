# Docker & Local Development Guide

This guide explains how to use Docker and local commands to run the Agendog stack. For local development, you will run the Next.js app directly on your machine for the best performance and hot-reloading experience, while the database and other services run in Docker containers.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Development Workflow](#development-workflow)
- [Production Workflow](#production-workflow)
- [Available Scripts](#available-scripts)
- [Services](#services)
- [Environment Variables](#environment-variables)
- [Connecting to the Database](#connecting-to-the-database)

## ✅ Prerequisites

- [Node.js](https://nodejs.org/en/) (v20+)
- [pnpm](https://pnpm.io/installation) (v9+)
- [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/)

## 🚀 Development Workflow

This is the recommended workflow for local development.

### Step 1: Start Backend Services with Docker

First, start the PostgreSQL database and pgAdmin using Docker. These services are defined in the `development` profile.

```bash
# Start the database and pgAdmin in the background
pnpm docker:dev
```

This command will:

- ✅ Start the PostgreSQL database, accessible on `localhost:5432`.
- ✅ Start pgAdmin, a database management UI, accessible at `http://localhost:5050`.

### Step 2: Run the Next.js App Locally

In a separate terminal, install dependencies and run the Next.js development server on your host machine.

```bash
# Install all monorepo dependencies
pnpm install

# Start the Next.js app in development mode
pnpm dev
```

Your application will be running at `http://localhost:3000` with hot-reloading enabled.

### Step 3: Stop Development Services

When you're finished, you can stop the Docker containers.

```bash
# Stop and remove the development containers and volumes
pnpm docker:dev:down
```

## 🏭 Production Workflow

To build and run the production version of the entire application stack with Docker, use the `production` profile.

### Build and Run

```bash
# Build all images and start all services in detached mode
pnpm docker:prod
```

This will:

- ✅ Build a production-optimized Docker image for the Next.js app.
- ✅ Start the Next.js app container.
- ✅ Start the PostgreSQL database container.

Your production application will be available at `http://localhost:3000`.

### Stop Production Services

```bash
# Stop and remove the production containers and volumes
pnpm docker:prod:down
```

## 📜 Available Scripts

| Script                  | Description                                                             |
| :---------------------- | :---------------------------------------------------------------------- |
| `pnpm dev`              | Starts the Next.js app locally (for development).                       |
| `pnpm docker:dev`       | Starts backend services (db, pgAdmin) via Docker for local development. |
| `pnpm docker:dev:down`  | Stops and removes development Docker services.                          |
| `pnpm docker:prod`      | Builds and starts the entire production stack via Docker.               |
| `pnpm docker:prod:down` | Stops and removes production Docker services.                           |
| `pnpm docker:logs`      | Tails the logs of all running Docker containers.                        |
| `pnpm db:shell`         | Opens a `psql` shell inside the running database container.             |

## 🔧 Services

### Services (Docker - `development` profile)

- **`db` (PostgreSQL)**: The application database.
- **`pgadmin`**: Database management UI.

### Services (Docker - `production` profile)

- **`web-app` (Next.js)**: The production-built Next.js application.
- **`db` (PostgreSQL)**: The application database.

## 🌍 Environment Variables

Create a `.env` file in the root of the project to configure your application. The `web-app` service in `compose.yaml` is configured to use it.

**Example `.env` for Local Development:**
When running `pnpm dev`, your Next.js app needs to connect to the database running in Docker.

```env
# .env

# For Next.js running locally connecting to the Dockerized DB
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/agendog"

# Public variables for the Next.js app
NEXT_PUBLIC_API_URL="http://localhost:3000"
```

## Connecting to the Database

### From Local Next.js App

Ensure your `DATABASE_URL` in the `.env` file points to `localhost:5432`.

### Using pgAdmin

1. Open pgAdmin in your browser: `http://localhost:5050`.
2. Log in with `admin@agendog.local` and password `admin`.
3. Create a new server connection:
   - **Host name/address**: `db` (this is the service name in `compose.yaml`)
   - **Port**: `5432`
   - **Username**: `postgres`
   - **Password**: `postgres` (or as set in your `.env` file)
   - Save the connection. You can now browse your database.
