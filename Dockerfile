# ============================================
# Stage 1: Base image with pnpm
# ============================================
FROM node:23-alpine AS base
RUN corepack enable pnpm
WORKDIR /app

# ============================================
# Stage 2: Install dependencies (monorepo-aware)
# ============================================
FROM base AS deps
RUN apk add --no-cache libc6-compat

# Copy workspace configuration files
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json .npmrc* ./

# Copy all package.json files to install dependencies
COPY apps/web-app/package.json ./apps/web-app/package.json
COPY packages/common/package.json ./packages/common/package.json

# Install all dependencies (including workspace packages)
RUN pnpm install --frozen-lockfile

# ============================================
# Stage 3: Build the Next.js app
# ============================================
FROM base AS builder
WORKDIR /app

# Copy node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/web-app/node_modules ./apps/web-app/node_modules
COPY --from=deps /app/packages/common/node_modules ./packages/common/node_modules

# Copy workspace configuration
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./

# Copy all source code
COPY apps/web-app ./apps/web-app
COPY packages/common ./packages/common

# Build the Next.js app
WORKDIR /app/apps/web-app
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

RUN pnpm run build

# ============================================
# Stage 4: Production runtime
# ============================================
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy public assets
COPY --from=builder /app/apps/web-app/public ./public

# Copy standalone build output
COPY --from=builder --chown=nextjs:nodejs /app/apps/web-app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/apps/web-app/.next/static ./apps/web-app/.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "apps/web-app/server.js"]