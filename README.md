# Field Notes

Field inspection application with a Flutter client, local SQLite storage, and a Spring Boot REST API. The data hierarchy is User → Customer → Site → Field Note.

## Architecture

- `backend/`: Java 21, Spring Boot 3.5.16, Spring Security, BCrypt, signed JWTs, Spring Data JPA, MySQL-compatible database, Flyway.
- `mobile/lib/domain/`: entities and repository contracts.
- `mobile/lib/data/`: SQLite repositories, models, secure token storage, HTTP client, reconciliation.
- `mobile/lib/presentation/`: BLoCs, screens, widgets and foreground sync coordinator.
- `scripts/`: backend launcher and live API smoke checks.

All customer/site/note writes go to SQLite first. A foreground coordinator syncs after local changes, sign-in, resume, connectivity changes and a periodic retry. SQLite queries and the outbox are scoped by user; different server origins use separate database files. Preferences remain local. Token and account identity are stored together in one platform secure-storage session record.

Pushes send customers before sites before notes, in batches of at most 200 records and 4 MiB. The server validates requests, enforces ownership and uses optimistic record versions instead of device clocks. Failed requests preserve the outbox. Retries of identical writes are acknowledged. Local revision counters protect edits made during an upload.

Pull currently reconciles the complete account snapshot, including tombstones. `since` remains accepted for compatibility but does not exclude rows: timestamp cursors can miss transactions that commit out of order. Unchanged accounts use conditional requests with ETags calculated from record versions; the cached tag is committed with its SQLite snapshot. Changed accounts still require a full snapshot; measure account size before a large deployment. Updates from the server cannot overwrite pending edits. Conflicts are preserved in SQLite and reviewed in Settings. A server-deleted record cannot be resurrected; retained local content can be copied into a new record.

Deleting a customer soft-deletes its sites and notes. Deleting a site soft-deletes its notes. SQLite migrations to v3 preserve records and outbox states, add constraints and versions, recover orphan rows, and scope conflict keys by account and record type. Inspection times use UTC storage and local display; DATETIME(6) supports dates beyond 2038.

## Features

| Capability | Implementation |
| --- | --- |
| Register, sign in, restore session, sign out | JWT API and secure local token |
| Customer and site CRUD | Local repositories and owned REST endpoints |
| Notes, description, inspection time, status | Editor and SQLite/API models |
| Photo attachment/removal | Image picker, compressed image and bounded base64 payload |
| GPS capture and manual coordinates | Geolocator and editable location field |
| Search and combined site/status filters | SQLite and server queries |
| Offline create/update/delete | Persistent outbox and tombstones |
| Automatic foreground/manual synchronization | Coordinator, Sync BLoC and Settings |
| Conflicts and concurrent edits | Version checks, local revisions and review screen |
| Default note status | Loaded before app startup; persisted locally |

## Backend setup

Install Java 21 and Maven 3.9+, and start MySQL 8+ or a maintained MariaDB release. Create `field_notes_db` and a dedicated application user. Give the migration account schema permissions; use a separate runtime account with data permissions in production if supplying `SPRING_FLYWAY_USER` and `SPRING_FLYWAY_PASSWORD`.

For MariaDB, set `DB_URL=jdbc:mariadb://localhost:3306/field_notes_db`; both vendor JDBC drivers are included and selected from the URL.

Required environment variables:

- `DB_PASSWORD`: dedicated database user's password.
- `JWT_SECRET`: random signing secret of at least 32 UTF-8 bytes, stored outside source control.

Optional variables: `DB_URL` (default `jdbc:mysql://localhost:3306/field_notes_db?serverTimezone=UTC`), `DB_USERNAME` (default `field_notes`), `SERVER_PORT` (8080), `JWT_EXPIRATION_MS` (24 hours), `CORS_ORIGINS` (comma-separated exact origins, default localhost/127.0.0.1 port 7357).

```powershell
cd backend
mvn clean package
java -jar target/field-notes-backend-1.0.0.jar
```

On this workstation, an ignored `backend/.env.local.json` contains generated local development credentials. `scripts/start-backend.ps1` loads it when present and also supports ordinary environment variables. It accepts `-Java` for a Java executable outside PATH. Never commit this file or deploy its local credentials.

Flyway upgrades the schema; Hibernate validates it. Automatic baselining is disabled, so an unversioned existing database needs an explicit reviewed migration rather than silently accepting an unknown schema. Back up production data before upgrades.

## Client setup

Use Flutter 3.47.6 / Dart 3.13.5 (the SDK used for this audit), with the Android SDK and Java 21 for Android builds. On Windows, Flutter plugins require Developer Mode or suitable symlink permissions. Run commands from `mobile/`:

```powershell
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter analyze
flutter test
flutter run
```

Configure the server using the gear on the sign-in screen. Android emulator development uses `http://10.0.2.2:8080`; desktop/web development uses `http://localhost:8080`. Physical devices need the development machine's reachable address. Sign out before changing servers. Release builds require HTTPS; put the backend behind TLS and set the deployed web origin in `CORS_ORIGINS`.

```powershell
flutter build apk --debug
flutter build apk --release
flutter build web
```

Android release signing uses `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`. Without these, release output is unsigned; debug keys are never used for release. iOS/macOS builds require macOS/Xcode, appropriate signing, and platform testing. Permission descriptions and secure-storage entitlements are included.

For web, serve the generated SQLite worker/WASM files at the app's origin. Token protection follows browser security constraints; deploy over HTTPS and protect the origin against injected scripts. SQLite inspection data relies on the operating system/browser profile's storage protection and is not independently encrypted by this application.

## API

- `POST /api/auth/register`, `POST /api/auth/login`.
- Owned CRUD at `/api/customers`, `/api/sites`, `/api/notes`.
- Note query parameters: `query`, `siteId`, `status`.
- `POST /api/sync/push`, `GET /api/sync/pull`.
- REST updates require the record's `version`; sync writes supply `baseVersion` (null for new records).
- Statuses: `DRAFT`, `IN_PROGRESS`, `COMPLETED`, `PENDING`.
- JSON requests are limited to 8 MiB. Auth endpoints allow 20 attempts per minute per remote address; production deployments should also enforce distributed edge rate limits, especially behind proxies.

## Verification

```powershell
cd backend
mvn clean package
cd ../mobile
flutter analyze
flutter test
cd ..
python scripts/api_smoke.py
cd mobile
flutter test test/live_sync_verification.dart
```

The smoke script needs a running backend and creates two uniquely named test accounts and test records. It soft-deletes its records after checking authentication, ownership, CRUD versions, search, sync idempotency and cascading tombstones. Override `API_BASE_URL` to use another dedicated test backend.

See `AUDIT_REPORT.md` for the actual audit results and platform verification limits. Passing tests are evidence for the scenarios exercised, not a guarantee that every possible bug has been eliminated.
