# Pet Services System Overview (Monorepo & Mobile First)

## 1. High-Level Architecture

We will adopt a **Monorepo** architecture (likely using Turborepo) to maximize code sharing between the Web App (Next.js) and the Mobile App (React Native/Expo).

### 1.1 Monorepo Structure

- **`apps/web`**: Next.js application (Admin Dashboard, Provider Portal, Web Booking).
- **`apps/mobile`**: React Native (Expo) application (Pet Owner App, Provider App).
- **`packages/api`**: Shared API definitions, schema, and client generation.
- **`packages/db`**: Database schema (Drizzle), migrations, and connection logic.
- **`packages/logic`**: Core business logic (Scheduling engine, Slot calculation, Validation).
- **`packages/ui`**: Shared UI components (Design system).

> **[NEEDS DETAIL]**: Do you want a specific Monorepo tool configuration (Turborepo vs Nx)? Do you want to use a shared UI library like Tamagui or NativeBase for cross-platform components?

## 2. Database Layer (Drizzle ORM)

We will replace Prisma with **Drizzle ORM** for better performance and lightweight SQL control.

### 2.1 Schema Overview

The schema remains similar conceptually but defined in TypeScript using Drizzle.

- **Users**: Owners and Providers.
- **Pets**: Profiles linked to Owners.
- **Services**: Defined by Providers (Duration, Price, Pet Type restrictions).
- **Schedules**: Working hours and Availability rules.
- **Bookings**: The core record linking User, Provider, Service, and Pet.

> **[NEEDS DETAIL]**: Do you need the exact Drizzle schema definition code now, or just the entity relationships?

## 3. API Strategy (REST + OpenAPI)

Since we are moving away from tRPC for better mobile compatibility, we will implement a **REST API** with **OpenAPI (Swagger)** documentation. This allows us to generate typed clients for both the Web and Mobile apps.

- **Framework**: Hono or Fastify (deployed via Next.js API Routes or a standalone Node server).
- **Documentation**: Auto-generated OpenAPI spec.
- **Client**: Generated TypeScript client (`openapi-typescript-codegen` or similar) shared in `packages/api`.

### 3.1 Key Endpoints

- `POST /auth/*`: Login, Register, Refresh Token.
- `GET /slots`: The heavy-lifting endpoint for calculating availability.
- `POST /bookings`: Transactional booking creation.
- `GET /pets`: CRUD for pets.

> **[NEEDS DETAIL]**: Do you want to see the specific API contract (Request/Response bodies) for the `slots` and `bookings` endpoints?

## 4. Core Logic (Shared Package)

This is the most critical part to reuse. The `packages/logic` folder will contain pure TypeScript functions.

### 4.1 Scheduling Engine (`getSlots`)

- **Input**: ProviderID, ServiceID, DateRange, PetDetails.
- **Logic**:
  1.  Fetch Provider's `Schedule` (Drizzle).
  2.  Fetch existing `Bookings` (Drizzle).
  3.  Calculate available time chunks.
  4.  Filter chunks based on Service Duration (adjusted for Pet Size).
- **Output**: Array of available start times.

> **[NEEDS DETAIL]**: This logic is complex. Do you want a deep dive into the algorithm, specifically how we handle "Resource Scheduling" (e.g., limited grooming tables) vs "User Scheduling"?

### 4.2 Booking Validation

- Ensures the slot is _still_ available (race condition check).
- Validates Pet eligibility for the Service.

## 5. Mobile App Specifics

The mobile app will consume the shared API and Logic.

- **Authentication**: Native login flows (Apple/Google Sign-In).
- **Push Notifications**: For booking reminders and updates.
- **Offline Mode**: Caching schedules and pet details.

> **[NEEDS DETAIL]**: Do you need a specification for the "Offline Sync" strategy? (e.g., how to handle booking requests when offline).

## 6. Next Steps

1.  **Initialize Monorepo**: Set up Turbo, Drizzle, and the basic package structure.
2.  **Implement DB Package**: Define Drizzle schema and run migrations.
3.  **Port Logic**: Move `slots.ts` logic to `packages/logic` and adapt for Drizzle.
4.  **Build API**: Create the REST endpoints.
5.  **Build Clients**: Start the Web and Mobile apps consuming the API.
