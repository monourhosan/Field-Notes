# Field Notes audit — 8 October 2026

The complete source and original requirements were inspected before changes. The current working tree was subsequently reviewed again as another developer's implementation, with adversarial tests aimed at ownership, interrupted uploads, concurrent edits, stale reviews, database migrations and malformed input. Existing user changes, including the already-deleted requirements file, were preserved.

## Architecture and requirements

The project is a Flutter client with presentation/BLoC, domain and data layers, backed by Spring Boot controllers/services/JPA repositories and a MySQL-compatible database. Users own customers; customers own sites; sites own notes. SQLite is the client source for reads and mutations. HTTP synchronization reconciles local changes with server records.

Registration/login, customer/site/note CRUD, photo attachment/removal, inspection time, GPS/manual location, search, combined site/status filters, offline changes, manual/automatic foreground sync, defaults and explicit conflict review are implemented. Account isolation, automatic sync, reliable conflict handling and combined filters were incomplete or unsafe in the inspected baseline and were repaired.

## Findings and repairs

| Area | Finding | Result |

| --- | --- | --- |

| Ownership | Local lists/outbox and cursor crossed account boundaries | User-scoped joins, account guards, server-specific database files |

| Security | Supplied IDs could merge over another user's records | Explicit collision rejection, owned parent checks, new-entity persist semantics |

| Sync | Device clock determined who overwrote whom | Server optimistic versions; stale writes become conflicts |

| Sync | Invalid parents could be silently acknowledged | Explicit conflicts; only persisted records are acknowledged |

| Transactions | Item-level exception handling could conceal failed batches | Storage failures roll back the transaction; client keeps outbox |

| Data loss | Pull could overwrite unsent edits | Pending changes remain local; conflicts retain both versions |

| Concurrent edits | Server could change between upload acknowledgement and pull | Acknowledgements return exact accepted versions; intervening edits are reviewed |

| Concurrent edits | Local changes/deletion during upload could be discarded or resurrected | Monotonic local revisions and pending deletion tombstones |

| Conflict review | Identical IDs across entity types collided in journal | Composite account/type/ID keys and v3 migration |

| Conflict review | Old review could discard a newer local edit | Current content displayed; reviewed local revision checked transactionally |

| Deletion | Parent deletion left active descendants | Server cascade soft deletion, local cascade hiding and tombstone reconciliation |

| Migration | Legacy local rows lacked constraints and could be orphaned | Foreign keys, indexes, preserved outbox and orphan recovery journal |

| Authentication | Token and identity were persisted separately | Atomic secure session record; legacy preferences migrated |

| Authentication | Bad credentials/oversize UTF-8 passwords and trimmed names were mishandled | Consistent 401/400 responses, bounds and normalization |

| API | Malformed JSON, nested null items, invalid queries and storage failures lacked reliable errors | Validation and structured client/server errors |

| Security | Default secrets/root database access, broad CORS, unlimited request size | Required external secrets, dedicated DB user, exact CORS, 8 MiB cap and auth rate limit |

| Networking | Requests had no timeout and release transport was insecure | Bounded HTTP requests, meaningful errors and HTTPS enforcement |

| UI persistence | Editor closed before storage success; photo/text could not be cleared | Save acknowledgement controls navigation; errors retain form; explicit nullable clearing |

| UI/state | Defaults and asynchronous list loads could be stale | Startup defaults, restartable loads, serialized mutation/auth handlers |

| Photos | Corrupt content could throw; decoding repeated on rebuilds | Cached decode and safe fallback rendering |

| Date/time | Local/UTC display differed; allowed inspection dates exceeded TIMESTAMP range | UTC persistence/local display; DATETIME(6) migration and range validation |

| Performance | Outbox counts loaded full photos; upload retained every payload; idle sync transferred full photos | SQL counts, bounded payload assembly, version-only ETags and conditional pulls |

| Queries | Lazy parent access caused repeated queries | Entity graphs for parent information and relationship indexes |

| Builds | Android cleartext manifest merge and Windows Kotlin cache failed | Explicit manifest overrides and disabled problematic incremental cache |

| Database driver | MySQL driver misidentified local MariaDB version | Both vendor drivers supported; local MariaDB URL selects its driver |

| Deployment | Release used debug signing; permissions/secure-storage setup incomplete | External release signing configuration, platform permissions and entitlements |

## Verification

- Backend: `mvn clean package` on Java 21 — **21 tests passed**, zero failures/errors/skips; runnable JAR produced.

- Flutter: `flutter analyze` — **no issues found**.

- Flutter: `flutter test` — **33 tests passed**, including SQLite migrations, cross-account isolation, offline CRUD, failed requests, upload timing, conflict handling, session storage, batching and editor success/failure.

- Android: `flutter build apk --debug` — **passed**; `mobile/build/app/outputs/flutter-apk/app-debug.apk` produced. A nonblocking SDK XML parser-version warning remains in bundled build tooling.

- Web: `flutter build web --debug` — **passed**; SQLite worker and WASM assets included. Browser startup and dashboard were inspected without changing the user's existing records.

- Live database: Flyway v2/v3 migrations applied and Hibernate schema validation/startup succeeded. Before v3, a SQL backup was saved outside the repository in the user's local audit cache.

- Live API: `scripts/api_smoke.py` — **33 checks passed** against the rebuilt server, including authentication, ownership, version conflicts, idempotent sync, cascading tombstones, search, conditional pulls/ETag invalidation, malformed/oversize credentials, nested null input and an inspection date in 2040.

- Repeated sync regression scenarios: another device editing after push, multiple edits while upload is in flight, deletion during first upload, lost/failed responses, logout during push, stale conflict decisions and a 205-record outbox.

- `git diff --check` passed; generated local credentials are ignored by Git. No credentials are included in this report.

## Verification limits and operational requirements

Camera/GPS permissions and native lifecycle behavior still require a physical device or emulator. iOS/macOS compilation and signing require a Mac with Xcode; they were not verified on this Windows workstation. Release signing keys and a deployed HTTPS endpoint were not supplied.

The local XAMPP database is MariaDB 10.4.32. Use a maintained database release for deployment; this audit did not replace or upgrade the user's existing database installation. The application requires production TLS, managed secrets, backups and edge rate limiting. SQLite inspection data uses OS/browser profile storage protection and is not separately encrypted.

Changed accounts still reconcile a complete snapshot, including inline photos. Conditional pulls avoid unchanged transfers, but large-account deployment needs measured load tests and potentially pagination/blob storage. Foreground synchronization is implemented; the OS does not guarantee synchronization while the application is terminated.

Passing tests establish the exercised behavior. This audit does not claim that every possible defect is eliminated or that untested platforms and deployment infrastructure are production-certified.


## Final production readiness verification — 8 October 2026

Rechecked the current working tree rather than relying only on previous results.

| Check | Evidence | Status |
| --- | --- | --- |
| Backend builds | Fresh Java 21 Maven clean/package, runnable JAR | Passed |
| Database works | MariaDB startup, Flyway validation, Hibernate validation and live reads/writes | Passed locally |
| Authentication works | Registration, login, invalid/oversize credentials, token rejection and ownership tests | Passed |
| APIs work | 33 fresh live API checks | Passed |
| Flutter app builds | Android release APK and web release compiled successfully | Passed |
| Offline mode works | Real SQLite file reopened after disconnected writes; data and outbox preserved | Passed in integration test |
| Sync works | Real backend upload/pull, two device databases, stale edit conflict and cascade tombstones | Passed in integration test |
| Tests pass | 21 backend tests, 33 standard Flutter tests, 1 explicit live Flutter integration test; analyzer has no issues | Passed |
| No critical bugs remain | No known unresolved critical application defects found by this audit and the exercised scenarios | Verified only within tested scope |

The live integration test is `mobile/test/live_sync_verification.dart`. It is run explicitly with `flutter test test/live_sync_verification.dart` against a running local/disposable backend; it creates a unique audit account and cleans up its records with tombstones. It does not run in the ordinary test suite, which does not need network access.

Final deployment clearance is conditional: native device acceptance, iOS/macOS if those targets are released, Android signing, deployed HTTPS/security configuration, a maintained production database and production backup/load verification still require the actual deployment environment.

### Release results

- Web release: `flutter build web --output=build/web-release` passed.
- Android release: `flutter build apk --release` passed; APK is approximately 58.4 MB.
- APK signature verification: `apksigner verify --verbose` returned `DOES NOT VERIFY` with a missing signing manifest. This is the expected unsigned artifact when no production keystore is configured; it is not cleared for distribution until signed and verified.
- Nonblocking native dependency warnings: geolocator's Android code uses deprecated APIs and Java 8 source/target settings. They did not prevent release compilation.
- ADB reported no connected devices or emulators. Native runtime acceptance was not performed.

**Final status:** backend, local database, authentication, APIs, Flutter builds, offline persistence, synchronization and automated tests pass in the tested environment. No known unresolved critical application defects were found in the exercised scope. Production deployment is not yet cleared because its signing, HTTPS/environment configuration, maintained database, device acceptance and backup/load verification have not been completed against the actual deployment target.
