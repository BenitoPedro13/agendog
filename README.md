# Agendog

Agendog is a modern, full-stack application built as a pnpm monorepo. It features a Next.js frontend and utilizes Docker to manage backend services for a clean and consistent development and production environment.

## ✨ Features

- **Monorepo Architecture**: Managed with `pnpm` workspaces for scalable code sharing and management.
- **Next.js Frontend**: A React framework for production-grade applications.
- **TypeScript**: For robust, type-safe code across the entire stack.
- **Dockerized Services**: Easy-to-manage backend services (like PostgreSQL) for development and production.
- **Consistent Tooling**: `ESLint` and `Prettier` for high-quality, consistent code.

## ✅ Prerequisites

Before you begin, ensure you have the following installed on your system:

- [Node.js](https://nodejs.org/en/) (v20 or higher)
- [pnpm](https://pnpm.io/installation) (v9 or higher)
- [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/)

## 🚀 Getting Started: Development Environment

Follow these steps to get your local development environment up and running.

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd agendog
```

### 2. Install Dependencies

Install all project dependencies using `pnpm`.

```bash
pnpm install
```

### 3. Set Up Environment Variables

Create a `.env` file in the root of the project by copying the example file. This file is required for the application to connect to the database.

```bash
cp .env.example .env
```

The default values in `.env.example` are configured to work with the local Docker setup.

### 4. Start Backend Services

Start the PostgreSQL database and pgAdmin using Docker. These services run in the background.

```bash
pnpm docker:dev
```

This will start:

- **PostgreSQL Database**: Accessible on `localhost:5432`.
- **pgAdmin UI**: Accessible at `http://localhost:5050`.

### 5. Run the Frontend Application

In a separate terminal, run the Next.js development server.

```bash
pnpm dev
```

Your application is now running at **[http://localhost:3000](http://localhost:3000)** with hot-reloading enabled.

## 🛑 Stopping the Environment

- To stop the Next.js development server, press `Ctrl + C` in its terminal.
- To stop the Docker services (database and pgAdmin), run:

```bash
pnpm docker:dev:down
```

## 🛠️ Available Scripts

Here are some of the most common scripts available from the root directory:

| Script                 | Description                                            |
| :--------------------- | :----------------------------------------------------- |
| `pnpm dev`             | Starts the Next.js app locally for development.        |
| `pnpm docker:dev`      | Starts backend services (db, pgAdmin) via Docker.      |
| `pnpm docker:dev:down` | Stops all development Docker services.                 |
| `pnpm docker:prod`     | Builds and starts the full production stack in Docker. |
| `pnpm format`          | Formats all code with Prettier.                        |
| `pnpm lint`            | Lints the entire codebase.                             |

For more details on the Docker setup, see `README.Docker.md`.
