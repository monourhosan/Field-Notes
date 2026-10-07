# Field Notes — Offline-First Site Inspection Platform

**Field Notes** is a production-grade, offline-first mobile inspection system and REST API backend designed for field technicians, inspectors, and engineers. It empowers mobile workers to document site visits, capture inspection notes, attach site photos, and record GPS coordinates with uninterrupted operation in remote, zero-connectivity environments, and seamlessly sync data whenever connectivity is restored.

---

## Architecture Overview

```
                      +---------------------------------------+
                      |       Flutter Mobile Application      |
                      |   Clean Architecture (Domain/Data/UI) |
                      |       BLoC State Management           |
                      +-------------------+-------------------+
                                          |
                +-------------------------+-------------------------+
                |                                                   |
       [Online: REST & Sync]                               [Offline: SQLite]
                |                                                   |
                v                                                   v
+-------------------------------+                  +-------------------------------+
|   Spring Boot 3 REST Backend   |                  |     Local SQLite Database     |
| - Spring Security 6 (JWT)     |                  | - Pending Create/Update/Delete|
| - Data Isolation per User     |                  | - Local Note Status Prefs     |
| - Push / Pull Sync Engine     |                  | - Embedded Offline Cache      |
+---------------+---------------+                  +-------------------------------+
                |
                v
+-------------------------------+
|      MariaDB / MySQL DB       |
| - Flyway Schema Migrations    |
| - Relational Hierarchy        |
+-------------------------------+
```

### Relational Hierarchy
Data ownership strictly follows the required relational model:
$$\text{User} \longrightarrow \text{Customer} \longrightarrow \text{Site} \longrightarrow \text{Field Note}$$

- **Multi-Tenancy & User Data Isolation**: Every resource is owned by an authenticated `User`. Users cannot view, modify, or sync records belonging to other users.
- **Offline Sync Engine**: Field technicians can create, update, or delete records offline. Mutations are tagged locally with `PENDING_CREATE`, `PENDING_UPDATE`, or `PENDING_DELETE`. When online, changes are batched to `/api/sync/push` and latest updates are pulled from `/api/sync/pull`.
- **Local-Only Preferences**: Configuration settings such as "Default Note Status" are persisted locally on the device (via `SharedPreferences`) and are **never** synced with the backend.

---

## Repository Structure

```
ati/
├── backend/                              # Java Spring Boot 3 Backend
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/fieldnotes/
│   │   │   │   ├── config/              # SecurityConfig, CorsConfig
│   │   │   │   ├── controller/          # Auth, Customer, Site, FieldNote, Sync Controllers
│   │   │   │   ├── dto/                 # Request/Response Data Transfer Objects
│   │   │   │   ├── exception/           # GlobalExceptionHandler & custom exceptions
│   │   │   │   ├── model/               # User, Customer, Site, FieldNote JPA entities
│   │   │   │   ├── repository/          # Spring Data JPA repositories with user scoping
│   │   │   │   ├── security/            # JwtAuthenticationFilter, JwtTokenProvider, UserPrincipal
│   │   │   │   └── service/             # Business logic & SyncService
│   │   │   └── resources/
│   │   │       ├── application.properties
│   │   │       ├── application-test.properties
│   │   │       └── db/migration/
│   │   │           └── V1__init_schema.sql # Flyway migration script
│   │   └── test/                        # Unit & Integration test suite (8 tests)
│   └── pom.xml
│
├── mobile/                               # Flutter Mobile Application
│   ├── lib/
│   │   ├── core/                        # AppTheme, NetworkConfig, Constants
│   │   ├── data/
│   │   │   ├── local/                   # SQLite DatabaseHelper, SettingsLocalDataSource
│   │   │   ├── models/                  # SQLite & JSON Data Models
│   │   │   └── repositories/            # Repository implementations (offline-first logic)
│   │   ├── domain/
│   │   │   ├── entities/                # Customer, Site, FieldNote, User, SyncStatus
│   │   │   └── repositories/            # Domain repository interfaces
│   │   ├── presentation/
│   │   │   ├── bloc/                    # Auth, Customer, Site, FieldNote, Sync, Settings BLoCs
│   │   │   ├── screens/                 # 11 Screen components
│   │   │   └── widgets/                 # StatusBadge, EmptyState, etc.
│   │   └── main.dart
│   ├── test/                            # BLoC, Model, and Widget test suite (9 tests)
│   └── pubspec.yaml
└── README.md
```

---

## Prerequisites & Environment Setup

### 1. Java & Maven
- **Java SE Development Kit**: JDK 21 or JDK 26 (tested with JDK 26.0.2).
- **Apache Maven**: Version 3.9+ (tested with Maven 3.9.9).

Verify Java and Maven installations:
```powershell
java -version
mvn -version
```

### 2. MariaDB / MySQL
- **MariaDB 10.4+** or **MySQL 8.0+** running on `localhost:3306`.
- Default credentials configured in `application.properties`:
  - **Host**: `localhost:3306`
  - **Database**: `field_notes_db`
  - **Username**: `root`
  - **Password**: *(empty by default for XAMPP)*

To start MariaDB/MySQL from XAMPP:
```powershell
& 'C:\xampp\mysql\bin\mysqld.exe' --defaults-file='C:\xampp\mysql\bin\my.ini' --standalone
```

Create the database:
```sql
CREATE DATABASE IF NOT EXISTS field_notes_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. Flutter & Dart
- **Flutter SDK**: 3.47+ / **Dart SDK**: 3.13.5+.
Verify Flutter installation:
```powershell
flutter --version
flutter doctor
```

---

## Backend Setup & Execution

### 1. Configuration (`application.properties`)
Located at `backend/src/main/resources/application.properties`:
```properties
server.port=8080

spring.datasource.url=jdbc:mysql://localhost:3306/field_notes_db?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
spring.datasource.username=root
spring.datasource.password=
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect

spring.flyway.enabled=true
spring.flyway.baseline-on-migrate=true

app.jwt.secret=404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970
app.jwt.expiration-ms=86400000
```

### 2. Build and Test
Run the comprehensive test suite (includes context loading, authentication, authorization, CRUD, data isolation, and sync tests):
```powershell
cd backend
mvn clean test
```
*Expected output: `Tests run: 8, Failures: 0, Errors: 0, Skipped: 0 — BUILD SUCCESS`*

### 3. Package and Run Backend
Package the executable Spring Boot JAR:
```powershell
mvn clean package -DskipTests
```
Launch the Spring Boot server:
```powershell
java -jar target/field-notes-backend-1.0.0.jar
# Or directly via Maven:
mvn spring-boot:run
```
The server starts at `http://localhost:8080`.

---

## REST API Documentation

All protected endpoints require an `Authorization` header with a Bearer JWT:
```http
Authorization: Bearer <your-jwt-token>
```

### Authentication Endpoints

#### `POST /api/auth/register`
Register a new field worker account.
- **Request Body:**
```json
{
  "username": "johndoe",
  "email": "john@fieldnotes.com",
  "password": "Password123!"
}
```
- **Response `201 Created`:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "Bearer",
  "id": "c62b5d03-fc28-4ef6-bb4d-621be14115f5",
  "username": "johndoe",
  "email": "john@fieldnotes.com"
}
```

#### `POST /api/auth/login`
Authenticate and obtain a JWT token.
- **Request Body:**
```json
{
  "username": "johndoe",
  "password": "Password123!"
}
```
- **Response `200 OK`:** Same structure as register.

---

### Customer Endpoints

- `GET /api/customers` — List all customers owned by authenticated user.
- `GET /api/customers/{id}` — Get single customer by ID.
- `POST /api/customers` — Create customer:
```json
{
  "id": "optional-client-uuid",
  "companyName": "Acme Industrial Corp",
  "contactInformation": "Jane Smith | 555-0192 | jane@acme.com"
}
```
- `PUT /api/customers/{id}` — Update customer details.
- `DELETE /api/customers/{id}` — Soft delete customer and cascading children.

---

### Site Endpoints

- `GET /api/sites` — List all sites owned by authenticated user. Optional query parameter: `?customerId=<id>`.
- `GET /api/sites/{id}` — Get single site by ID.
- `POST /api/sites` — Create site:
```json
{
  "id": "optional-client-uuid",
  "customerId": "c62b5d03-fc28-4ef6-bb4d-621be14115f5",
  "siteName": "Substation Alpha",
  "address": "450 Industrial Parkway, Sector 4"
}
```
- `PUT /api/sites/{id}` — Update site details.
- `DELETE /api/sites/{id}` — Delete site.

---

### Field Note Endpoints

- `GET /api/notes` — List notes with optional filtering:
  - `?query=inspection` (matches title or description)
  - `?siteId=<id>` (filters by site)
  - `?status=DRAFT|IN_PROGRESS|COMPLETED` (filters by status)
- `GET /api/notes/{id}` — Get single note by ID.
- `POST /api/notes` — Create field note:
```json
{
  "id": "optional-client-uuid",
  "siteId": "8f3b2a1c-99d1-4e2a-89a1-cb904a0e2f11",
  "title": "Transformer Leakage Inspection",
  "description": "Observed moderate coolant weeping from gasket B. Pressure remains nominal.",
  "status": "IN_PROGRESS",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "photoPath": "/data/user/0/com.fieldnotes.app/app_flutter/photo_01.jpg"
}
```
- `PUT /api/notes/{id}` — Update field note.
- `DELETE /api/notes/{id}` — Delete field note.

---

### Synchronization Endpoints (Offline-First)

#### `POST /api/sync/push`
Push offline changes (batch inserts, updates, and deletes) from device to backend.
- **Request Body:**
```json
{
  "customers": [
    {
      "id": "uuid-1",
      "companyName": "Apex Energy",
      "contactInformation": "support@apex.com",
      "syncAction": "CREATE"
    }
  ],
  "sites": [
    {
      "id": "uuid-2",
      "customerId": "uuid-1",
      "siteName": "Turbine 4 Facility",
      "address": "Ridge Road 12",
      "syncAction": "CREATE"
    }
  ],
  "notes": [
    {
      "id": "uuid-3",
      "siteId": "uuid-2",
      "title": "Bearing Temperature Check",
      "description": "Temperature is normal at 68C.",
      "status": "COMPLETED",
      "latitude": 42.123,
      "longitude": -71.456,
      "photoPath": null,
      "syncAction": "CREATE"
    }
  ]
}
```
- **Response `200 OK`:**
```json
{
  "success": true,
  "processedCustomers": 1,
  "processedSites": 1,
  "processedNotes": 1,
  "message": "Sync push completed successfully"
}
```

#### `GET /api/sync/pull?since={timestampMillis}`
Pull all records updated or created on the server after the given timestamp.
- **Response `200 OK`:**
```json
{
  "customers": [...],
  "sites": [...],
  "notes": [...],
  "serverTime": 1728345600000
}
```

---

## Mobile Application Setup & Execution

### 1. Configure Backend Host
Edit `mobile/lib/core/constants/network_config.dart` to match your target environment:
- **Android Emulator**: `http://10.0.2.2:8080/api` *(default)*
- **Physical Device**: `http://<your-machine-lan-ip>:8080/api`
- **Windows / macOS / Web**: `http://localhost:8080/api`

### 2. Dependencies & Static Analysis
```powershell
cd mobile
flutter pub get
flutter analyze
```
*Expected output: `No issues found!`*

### 3. Run Mobile Test Suite
```powershell
flutter test
```
*Expected output: `All tests passed! (9 tests)`*

### 4. Run the Mobile App
Connect an Android device or start an Android emulator, then run:
```powershell
flutter run
```

---

## Key Features & User Flows

1. **Secure Registration & Login**: Technicians sign in with email and password. JWT tokens are stored securely in encrypted storage.
2. **Dashboard Overview**: Displays summary statistics (Total Customers, Total Sites, Total Field Notes, and Pending Offline Sync count) with quick access cards.
3. **Hierarchical Navigation**:
   - Customers list with search and contact info.
   - Customer details showing all associated sites with one-tap site creation.
   - Site details showing site metadata and all recorded field notes.
4. **Rich Note Editor**:
   - Field Note title and detailed description.
   - Note Status (`DRAFT`, `IN_PROGRESS`, `COMPLETED`).
   - Automatically preselects the user's preferred "Default Note Status" configured in Settings.
   - One-tap GPS location capture with latitude/longitude accuracy.
   - Camera image capture & photo gallery attachment.
5. **Offline Synchronization Engine**:
   - Works 100% offline using an embedded SQLite database.
   - Status indicators highlight items awaiting synchronization.
   - Manual sync trigger button on Dashboard with real-time status and item counters.
6. **Local Preferences (Settings Screen)**:
   - Configure "Default Note Status" (`DRAFT`, `IN_PROGRESS`, `COMPLETED`).
   - Saved locally via `SharedPreferences`.
   - Never synced with backend, preserving technician customization.

---

## Testing Verification Summary

| Component | Test Suite | Results |
|:---|:---|:---:|
| **Backend** | Spring Boot Context (`FieldNotesApplicationTests`) | **PASSED** |
| **Backend** | Authentication & BCrypt (`AuthServiceTest`) | **PASSED** |
| **Backend** | Customer & Site CRUD & Isolation (`CustomerAndSiteServiceTest`) | **PASSED** |
| **Backend** | Field Note Search, Filter & Push/Pull Sync (`FieldNoteSearchAndSyncTest`) | **PASSED** |
| **Mobile** | SQLite Models & JSON Serialization (`database_and_model_test.dart`) | **PASSED** |
| **Mobile** | Customer BLoC State Management (`customer_bloc_test.dart`) | **PASSED** |
| **Mobile** | Field Note Search & Filter BLoC (`field_note_bloc_test.dart`) | **PASSED** |
| **Mobile** | UI Component & Badge Rendering (`widget_test.dart`) | **PASSED** |
| **Analyzer**| Flutter Lints & Dart Analyzer (`flutter analyze`) | **0 issues** |
#   F i e l d - N o t e s  
 