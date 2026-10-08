# installation.pdf implementation verification

Reviewed against all three pages of `C:/Users/lette/Downloads/installation.pdf` on 8 October 2026. The PDF is the requirements source; its document notes are distinguished from the user's instruction to implement the application. The PDF was not modified.

All specified software capabilities have implementations. Verification covers automated behavior, real SQLite files, a real MySQL backend, and compilation. It does not certify hardware permission dialogs, native device behavior, signed distribution, deployment infrastructure, or the document's preference concerning use of coding agents.

## Requirement mapping

| PDF intention | Implementation | Evidence |
| --- | --- | --- |
| Field Notes mobile app and REST backend | Flutter client and Java/Spring Boot backend | Android/web builds and backend JAR |
| Online account registration and login | Auth controllers, BCrypt credentials, JWT authentication; login/register screens | Backend tests and live API registration/login checks |
| User -> Customer -> Site -> Field Note hierarchy | Relational foreign keys in MySQL and SQLite; owned repository queries | Database migrations, ownership tests, hierarchy integration test |
| Customer name and contact information | Customer entity/model, forms, local repository and REST DTOs | Offline CRUD tests; server recovery retains contact information |
| Site name, address and customer | Site entity/model, forms, parent validation and REST DTOs | Offline CRUD tests; server recovery retains address and hierarchy |
| Note site, title, description, location, date/time, status and optional photo | Editor, model, local repository and REST DTOs | SQLite tests and live note payload, photo and UTC date verification |
| Create, view, edit and delete all three record types | Customer/site/note screens and local/API CRUD | Backend and client tests, live API checks and cascade integration |
| Work online and offline | SQLite is the source for all reads and mutations; persistent pending records | Writes while HTTP is disconnected; real database close/reopen |
| Automatically sync when connectivity returns | Coordinator observes connectivity, login, startup, resume and mutations; periodic retry handles reachability changes | Coordinator widget test covers startup, reconnection, resume, logout and edits during upload |
| Restore server data after reinstall/local-data clearing | New login retrieves account snapshot into an empty local database | Live test clears preferences and secure session, logs in again, restores a fresh SQLite file |
| Search title, description, site or customer | SQLite relational query and backend JOIN query | Client assertions for all four fields and live API search checks |
| Filter by status or site | Combined query filters and list controls | Repository tests; sync refresh preserves active search/site/status filters |
| Handle location permission | Permission checks, denied/permanent denial messages, settings actions, GPS timeout and manual coordinates | Widget tests for disabled GPS and both denial states; physical device acceptance remains |
| Handle camera/gallery permission | Image picker, caught plugin errors, cancellation handling and preserved form | Widget tests exercise both camera and gallery permission failures; physical device acceptance remains |
| Clean, easy-to-use UI | Hierarchy navigation, forms, search/filter controls, empty/error states, sync indicator and conflict review | Widget tests, previous browser review, safe unavailable-site selection and readable date labels; ease of use remains a human acceptance judgment |
| Settings: Default Note Status | Local preference loaded before startup and applied to new notes | Restart persistence test and editor default-status assertion |
| Default status need not sync | Preference excluded from API/sync models | Settings repository and request payload inspection |
| Flutter with BLoC, SQLite/Hive and REST | Flutter, flutter_bloc, SQLite and HTTP repositories | Dependency/configuration inspection; analyzer and tests |
| Java + Spring Boot with MySQL/PostgreSQL | Java 21, Spring Boot 3.5.16, MySQL 8.4.11 | Fresh backend build; actual MySQL startup and integration checks |
| Authentication and data isolation | Owned server queries, collision checks, account-scoped SQLite/outbox and server-specific local files | Cross-account tests, unauthorized API checks and logout-during-sync regression |
| Related information through relationships/JOINs, without duplicate storage | Server JPA relationships/entity graphs and JOINs; local normalized tables and JOINs | Migration and repository inspection, search/hierarchy tests |
| Developer chooses schema/API/sync design | Flyway migrations, versioned REST/sync endpoints, bounded upload batches, tombstones and conflicts | Migration, retry, concurrency, conflict and cascade tests |

## Additional repairs for this implementation pass

- Automatic synchronization starts for an already restored session and schedules another pass when local changes occur during a running upload.
- Sync refresh retains the selected customer scope and note search/site/status filters.
- Unavailable preselected sites cannot trigger the Flutter dropdown assertion; saving requires a valid visible selection.
- Disabled GPS and permanent permission denial offer a Settings action; GPS acquisition has a finite timeout.
- Android uses the system camera/gallery picker without unnecessary broad photo-library/storage permissions, following the [image_picker setup documentation](https://pub.dev/packages/image_picker). iOS usage descriptions remain configured.
- Date labels and related-record text use readable separators.
- Live recovery verification uses a completely new login/session and database, and checks photo/contact/address restoration.
- MySQL now runs separately from the original MariaDB instance. Existing records and migration history were copied without removing the original database, and record counts were compared.
- CI now matches Maven, Java 21 and Flutter, with MySQL-backed API and offline/recovery verification plus Android/web compilation.

## Verification and limits

See the latest verification section in [AUDIT_REPORT.md](AUDIT_REPORT.md) for executed commands and final counts. Both the copied account database and an isolated empty MySQL schema were exercised. The empty schema applied migrations V1-V3 and passed Hibernate validation before live API and Flutter integration checks.

Automatic sync is supported while the app is active and on resume. A terminated application cannot guarantee an immediate upload; pending changes remain durable and upload when the app is reopened. Data already synchronized restores after reinstall; unsynchronized data erased with local storage cannot be recovered from the server.

Android release builds require the owner's signing keys and an HTTPS backend before distribution. No native device/emulator was available for real camera/GPS/lifecycle acceptance. iOS/macOS require a Mac/Xcode if those targets are released. Hosted CI was not run from this uncommitted working tree.

The bundled Flyway 11.7.2 emits a MySQL 8.4 compatibility warning. Actual migrations, validation and database operations pass against MySQL 8.4.11; the warning is retained and reported instead of being suppressed. Large-account load testing and production backups/TLS/secrets still depend on the deployment environment.

The final PDF page allows partial submissions and asks applicants to avoid heavy reliance on agentic coding tools. The user explicitly requested agent implementation. That software work is authorized, but it cannot retroactively satisfy a preference about the applicant's own unaided work. The project should be reviewed and explained by its owner, with assistance disclosed where required.
