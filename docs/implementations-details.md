# Detailed Implementation Specifications

This document expands on the System Overview, providing the specific code structures and logic required for implementation.

## 1. Technology Stack Decisions

- **Monorepo**: Turborepo (for high-performance build caching).
- **Mobile/Web Sharing**: Solito (Next.js + Expo router integration).
- **UI Library**: Tamagui (for shared, performant styles on Web & Native).
- **Database**: PostgreSQL + Drizzle ORM.
- **API**: Hono (lightweight, edge-compatible) + Zod (validation).

## 2. Database Schema (Drizzle ORM)

We will use `drizzle-orm/pg-core` to define the schema.

### 2.1 Users & Auth

```typescript
// packages/db/schema/users.ts
import { pgTable, text, timestamp, pgEnum } from 'drizzle-orm/pg-core';

export const userRoleEnum = pgEnum('user_role', ['OWNER', 'PROVIDER', 'ADMIN']);

export const users = pgTable('users', {
  id: text('id').primaryKey(), // CUID or UUID
  email: text('email').notNull().unique(),
  name: text('name'),
  role: userRoleEnum('role').default('OWNER'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});
```

### 2.2 Pets

```typescript
// packages/db/schema/pets.ts
import {
  pgTable,
  text,
  timestamp,
  doublePrecision,
  pgEnum,
} from 'drizzle-orm/pg-core';
import { users } from './users';

export const petTypeEnum = pgEnum('pet_type', ['DOG', 'CAT', 'BIRD', 'OTHER']);
export const petSizeEnum = pgEnum('pet_size', [
  'SMALL',
  'MEDIUM',
  'LARGE',
  'GIANT',
]);

export const pets = pgTable('pets', {
  id: text('id').primaryKey(),
  ownerId: text('owner_id')
    .references(() => users.id, { onDelete: 'cascade' })
    .notNull(),
  name: text('name').notNull(),
  type: petTypeEnum('type').notNull(),
  size: petSizeEnum('size').default('MEDIUM'),
  breed: text('breed'),
  weight: doublePrecision('weight'), // kg
  medicalNotes: text('medical_notes'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});
```

### 2.3 Services & Variations

```typescript
// packages/db/schema/services.ts
import {
  pgTable,
  text,
  integer,
  doublePrecision,
  jsonb,
} from 'drizzle-orm/pg-core';
import { users } from './users';

export const services = pgTable('services', {
  id: text('id').primaryKey(),
  providerId: text('provider_id')
    .references(() => users.id, { onDelete: 'cascade' })
    .notNull(),
  name: text('name').notNull(),
  description: text('description'),
  basePrice: doublePrecision('base_price').notNull(),
  baseDuration: integer('base_duration').notNull(), // minutes
  acceptedPetTypes: jsonb('accepted_pet_types').$type<string[]>(), // ['DOG', 'CAT']
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

export const serviceVariations = pgTable('service_variations', {
  id: text('id').primaryKey(),
  serviceId: text('service_id')
    .references(() => services.id, { onDelete: 'cascade' })
    .notNull(),
  petSize: text('pet_size').notNull(), // Matches petSizeEnum
  price: doublePrecision('price').notNull(),
  duration: integer('duration').notNull(),
});
```

### 2.4 Schedules & Availability

```typescript
// packages/db/schema/schedules.ts
import { pgTable, text, integer, time } from 'drizzle-orm/pg-core';
import { users } from './users';

export const schedules = pgTable('schedules', {
  id: text('id').primaryKey(),
  providerId: text('provider_id')
    .references(() => users.id, { onDelete: 'cascade' })
    .notNull(),
  name: text('name').notNull(),
  timeZone: text('time_zone').notNull(),
});

export const availabilities = pgTable('availabilities', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  scheduleId: text('schedule_id')
    .references(() => schedules.id, { onDelete: 'cascade' })
    .notNull(),
  dayOfWeek: integer('day_of_week').notNull(), // 0-6
  startTime: time('start_time').notNull(),
  endTime: time('end_time').notNull(),
});
```

### 2.5 Bookings

```typescript
// packages/db/schema/bookings.ts
import {
  pgTable,
  text,
  timestamp,
  doublePrecision,
  pgEnum,
} from 'drizzle-orm/pg-core';
import { users } from './users';
import { pets } from './pets';
import { services } from './services';

export const bookingStatusEnum = pgEnum('booking_status', [
  'PENDING',
  'CONFIRMED',
  'CANCELLED',
  'COMPLETED',
  'NO_SHOW',
]);

export const bookings = pgTable('bookings', {
  id: text('id').primaryKey(),
  uid: text('uid').notNull().unique(), // Public reference
  serviceId: text('service_id')
    .references(() => services.id)
    .notNull(),
  providerId: text('provider_id')
    .references(() => users.id)
    .notNull(),
  userId: text('user_id')
    .references(() => users.id)
    .notNull(),
  petId: text('pet_id')
    .references(() => pets.id)
    .notNull(),

  startTime: timestamp('start_time').notNull(),
  endTime: timestamp('end_time').notNull(),

  status: bookingStatusEnum('status').default('CONFIRMED'),
  price: doublePrecision('price').notNull(), // Snapshot
  notes: text('notes'),

  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});
```

## 3. Scheduling Algorithm (`packages/logic`)

The core `getSlots` function.

```typescript
// packages/logic/src/scheduling.ts
import { addMinutes, areIntervalsOverlapping, format, parse } from 'date-fns';

type Slot = { time: Date };
type Availability = { dayOfWeek: number; startTime: string; endTime: string };
type Booking = { startTime: Date; endTime: Date };

export function getSlots(
  date: Date,
  durationMinutes: number,
  availability: Availability[],
  existingBookings: Booking[],
  timeZone: string,
): Slot[] {
  const dayOfWeek = date.getDay();
  const dayAvailability = availability.filter((a) => a.dayOfWeek === dayOfWeek);

  const slots: Slot[] = [];

  for (const range of dayAvailability) {
    // Convert string times (e.g., "09:00") to Date objects for the specific date
    let currentTime = parseTime(date, range.startTime, timeZone);
    const endTime = parseTime(date, range.endTime, timeZone);

    while (addMinutes(currentTime, durationMinutes) <= endTime) {
      const slotEnd = addMinutes(currentTime, durationMinutes);

      // Check for conflicts
      const isConflict = existingBookings.some((booking) =>
        areIntervalsOverlapping(
          { start: currentTime, end: slotEnd },
          { start: booking.startTime, end: booking.endTime },
        ),
      );

      if (!isConflict) {
        slots.push({ time: currentTime });
      }

      // Increment by step (e.g., 15 mins or duration)
      // For simplicity, we step by duration, but usually you want a smaller step (e.g. 15m)
      currentTime = addMinutes(currentTime, 15);
    }
  }

  return slots;
}

function parseTime(date: Date, timeString: string, timeZone: string): Date {
  // Implementation to combine date + time string in specific timezone
  // ...
  return new Date(); // Placeholder
}
```

## 4. API Contracts (REST)

### 4.1 `GET /api/slots`

**Query Params**:

- `providerId`: string
- `serviceId`: string
- `petId`: string (to calculate duration)
- `from`: ISO Date
- `to`: ISO Date

**Response**:

```json
{
  "slots": {
    "2023-10-27": ["2023-10-27T09:00:00Z", "2023-10-27T09:30:00Z"],
    "2023-10-28": []
  }
}
```

### 4.2 `POST /api/bookings`

**Body**:

```json
{
  "providerId": "user_123",
  "serviceId": "service_456",
  "petId": "pet_789",
  "startTime": "2023-10-27T09:00:00Z",
  "notes": "Please be gentle, he is shy."
}
```

**Response**:

```json
{
  "id": "booking_abc",
  "status": "CONFIRMED",
  "price": 50.0
}
```

## 5. Offline Sync Strategy (Mobile)

For the mobile app, we need to handle intermittent connectivity.

1.  **Read Caching**:

    - Use `TanStack Query` (React Query) with `persist-query-client`.
    - Cache `User`, `Pets`, and `Upcoming Bookings` to `AsyncStorage`.
    - _Stale-While-Revalidate_ policy for UI.

2.  **Write Queue**:

    - If offline, Booking creation is **blocked** (requires server confirmation to prevent double-booking).
    - _Exception_: "Draft" bookings can be saved locally.
    - Pet creation/updates can be queued. Use a specialized queue (e.g., `tanstack-query` mutations with retry or a custom Redux queue) to replay requests when online.

3.  **Conflict Resolution**:
    - Server wins. If a queued update fails due to server state change, prompt user to refresh.
