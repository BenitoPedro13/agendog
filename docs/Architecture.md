# Pet Services Scheduling App Architecture

## 1. Overview

This document outlines the architecture for a new Pet Services Scheduling Application. The app connects Pet Owners with Service Providers (Groomers, Vets, Walkers) and allows for seamless appointment booking. We will leverage the robust scheduling logic from the existing `markado` repository, adapting it for the specific needs of the pet industry.

## 2. Core Components

### 2.1 User Roles

- **Pet Owner**: The customer who books services for their pets.
- **Service Provider**: The professional (Groomer, Vet) offering services.
- **Admin**: Platform administrator.

### 2.2 Pet Management (New Module)

Unlike the current system which focuses on human attendees, this app requires a `Pet` entity.

- **Pet Profile**: Name, Breed, Age, Weight, Medical History, Vaccination Status.
- **Association**: Pets are linked to Pet Owners.

### 2.3 Service Management (Adapted `EventType`)

We will reuse the `EventType` concept but enhance it for pet services.

- **Service Types**: Grooming, Vet Consultation, Dog Walking, Boarding.
- **Attributes**: Duration, Price, Accepted Pet Types (e.g., "Dogs only", "Cats only"), Size Restrictions.
- **Resources**: Some services might require specific resources (e.g., "Large Grooming Table", "X-Ray Machine").

### 2.4 Scheduling Engine (Reused Logic)

We will reuse the core scheduling logic from `src/packages/lib/slots.ts` and `src/packages/features/bookings/lib/handleNewBooking.ts`.

- **Availability**: Service Providers define their working hours (`Schedule` and `Availability` models).
- **Slot Calculation**: The `getSlots` function will be used to calculate available times based on provider availability, service duration, and existing bookings.
- **Conflict Detection**: We need to ensure a provider isn't double-booked.

### 2.5 Booking Management (Adapted `Booking`)

The `Booking` model will be linked to a `Pet` in addition to the `User` (Provider) and `Attendee` (Owner).

- **Flow**:
  1.  Owner selects a Service Provider and Service.
  2.  Owner selects a Pet.
  3.  App displays available slots (using `getSlots`).
  4.  Owner selects a slot.
  5.  Booking is created (using adapted `handleNewBooking`).

## 3. Data Model (Prisma Schema)

We will build upon the existing schema, adding/modifying the following:

```prisma
// Existing User model (Service Provider or Pet Owner)
model User {
  // ... existing fields
  pets Pet[] // Relation to pets owned by the user
}

// New Pet model
model Pet {
  id        String   @id @default(cuid())
  ownerId   String
  owner     User     @relation(fields: [ownerId], references: [id], onDelete: Cascade)
  name      String
  type      PetType  // DOG, CAT, etc.
  breed     String?
  birthDate DateTime?
  weight    Float?
  bookings  Booking[]
}

enum PetType {
  DOG
  CAT
  BIRD
  OTHER
}

// Adapted Booking model
model Booking {
  // ... existing fields
  petId     String?
  pet       Pet?     @relation(fields: [petId], references: [id])
}

// Adapted EventType model
model EventType {
  // ... existing fields
  acceptedPetTypes PetType[] // Array of accepted pet types
}
```

## 4. Key Logic Adaptation

### 4.1 `handleNewBooking.ts`

- **Input**: Needs to accept `petId`.
- **Validation**: Check if the selected `petId` belongs to the booking user. Check if the `EventType` accepts the pet's type.
- **Notifications**: Emails should include Pet details.

### 4.2 `slots.ts`

- The core logic for time calculation remains largely the same.
- If we implement "Resource Scheduling" (e.g., limited number of grooming tables), `getSlots` might need to check resource availability in addition to user availability.

## 5. Technology Stack

- **Framework**: Next.js (App Router)
- **Database**: PostgreSQL with Prisma ORM
- **API**: tRPC (for type-safe API calls)
- **Styling**: Tailwind CSS
- **Scheduling**: Custom logic adapted from `markado`

## 6. Next Steps

1.  Initialize the new Next.js project.
2.  Copy and adapt the `Prisma` schema.
3.  Port `slots.ts` and `date-ranges.ts` to the new project.
4.  Implement `Pet` CRUD operations.
5.  Port and adapt `handleNewBooking.ts`.
6.  Build the UI for Booking with Pet selection.
