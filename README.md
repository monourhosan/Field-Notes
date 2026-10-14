# Field Notes

A full-stack mobile application and REST backend for field workers to record and manage site inspection notes with seamless offline capability.

## Overview

The application follows the natural hierarchy:
**User → Customer → Site → Field Note**

- **Customer:** Name, Contact Information.
- **Site:** Site Name, Address, associated Customer.
- **Field Note:** Title, Description, Location (GPS coordinates), Date & Time, Status, and an optional Photo.

All operations (create, view, edit, delete, search, filter) work seamlessly **offline-first** using a local SQLite database on the mobile device. When internet connectivity is restored, local changes automatically synchronize with the Spring Boot backend. If the app is reinstalled or local data is cleared, logging in restores all data from the backend.

## Tech Stack

### Mobile App
- **Framework:** Flutter (Dart)
- **State Management:** BLoC (`flutter_bloc`)
- **Local Storage:** SQLite (`sqflite` / `sqflite_common_ffi`)
- **Networking:** REST API communication via `http` client
- **Hardware Integration:** `geolocator` for GPS and `image_picker` for camera/gallery photo capture

### Backend
- **Framework:** Java 21, Spring Boot 3
- **Database:** MySQL (relational schema with Flyway migrations)
- **Security:** Spring Security, BCrypt password hashing, JWT authentication
- **Data Isolation:** User-scoped queries and repositories; users only access their own records
- **Relational Design:** Normalized relational model using JPA relationships (`@ManyToOne`, `@OneToMany`) and JOIN queries without duplicating customer or site information

## Features

- **Authentication:** Online user registration and login with secure token storage.
- **Customer & Site Management:** Full CRUD operations for customers and sites.
- **Field Notes:** Full CRUD for notes with status tracking, formatted date/time, GPS coordinates, and optional photos.
- **Offline-First:** All mutations write to local SQLite first with persistent outbox queueing.
- **Automatic Sync:** Syncs automatically upon reconnection, app resume, login, or manual trigger.
- **Data Recovery:** Reinstalling or clearing local data restores complete data upon login.
- **Search:** Search field notes across title, description, site name, or customer name.
- **Filters:** Filter notes by status (`DRAFT`, `IN_PROGRESS`, `COMPLETED`, `PENDING`), by site, or combined.
- **Permissions:** Graceful handling for camera, gallery, and GPS location permissions with fallback to manual entry.
- **Settings:** Screen with "Default Note Status" option that is saved locally and auto-applied when creating new notes.

## Backend Setup

### Prerequisites
- Java 21+
- Maven 3.9+
- MySQL 8.x

### Configuration
Configure your database connection and JWT secret in environment variables or `backend/src/main/resources/application.yml`:

- `DB_URL`: `jdbc:mysql://localhost:3306/field_notes_db?serverTimezone=UTC`
- `DB_USERNAME`: Database username (default: `field_notes`)
- `DB_PASSWORD`: Database password
- `JWT_SECRET`: Secret key for JWT signing (at least 32 characters)
- `SERVER_PORT`: `8080` (default)

### Build and Run
```powershell
cd backend
mvn clean package
java -jar target/field-notes-backend-1.0.0.jar
```

Alternatively, you can launch using the included PowerShell script:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start-mysql.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start-backend.ps1
```

## Mobile App Setup

### Prerequisites
- Flutter SDK (3.x+)
- Android SDK / emulator or physical device

### Run App
From the `mobile/` directory:
```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

### Build APK
```powershell
flutter build apk --debug
flutter build apk --release
```

## API Endpoints

### Authentication
- `POST /api/auth/register` — Create a new worker account
- `POST /api/auth/login` — Sign in and receive JWT token

### Customers
- `GET /api/customers` — List authenticated user's customers
- `POST /api/customers` — Create a customer
- `GET /api/customers/{id}` — Get customer details
- `PUT /api/customers/{id}` — Update a customer
- `DELETE /api/customers/{id}` — Delete a customer (cascades to sites & notes)

### Sites
- `GET /api/sites` — List authenticated user's sites
- `POST /api/sites` — Create a site under a customer
- `GET /api/sites/{id}` — Get site details
- `PUT /api/sites/{id}` — Update a site
- `DELETE /api/sites/{id}` — Delete a site (cascades to notes)

### Field Notes
- `GET /api/notes?query={q}&siteId={siteId}&status={status}` — Search and filter notes
- `POST /api/notes` — Create a field note
- `GET /api/notes/{id}` — Get field note details
- `PUT /api/notes/{id}` — Update a field note
- `DELETE /api/notes/{id}` — Delete a field note

### Synchronization
- `POST /api/sync/push` — Push offline outbox batch (customers, sites, notes)
- `GET /api/sync/pull` — Pull current account snapshot
