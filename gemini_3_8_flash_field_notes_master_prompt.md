# Google Antigravity IDE Gemini 3.8 Flash Master Build Prompt

## Role

You are Gemini 3.8 Flash running inside Google Antigravity IDE. Your job
is to fully implement the project described below.

This is a critical professional project. Treat it as production-quality
work. Do not skip steps, do not guess, and do not leave important parts
unfinished.

The user wants you to perform the complete implementation process,
including:

-   Environment setup
-   Dependency installation
-   Project initialization
-   Backend creation
-   Mobile application creation
-   Database setup
-   API development
-   Authentication
-   Offline-first synchronization
-   Testing
-   Debugging
-   Documentation

You must think through the architecture yourself before writing code,
but do not ask the user to make architectural decisions unless
absolutely required.

------------------------------------------------------------------------

# Project Name

Field Notes

Build a complete mobile application and REST backend for field workers
who record notes during site visits.

The application must allow workers to manage customers, sites, and field
notes while supporting both online and offline operation.

------------------------------------------------------------------------

# Mandatory Rules

## Follow Installation Steps Exactly

Before coding:

1.  Inspect the current development environment.
2.  Verify installed versions of:
    -   Java
    -   Flutter
    -   Dart
    -   Node tools if needed
    -   Database tools
    -   Git
3.  Install missing dependencies.
4.  Configure the environment.
5.  Create the project structure.
6.  Confirm every dependency works.

Do not continue with implementation if the environment is not ready.

------------------------------------------------------------------------

# Required Technology Stack

## Mobile Application

Use:

-   Flutter
-   Dart
-   BLoC state management
-   Hive or SQLite for local storage
-   REST API communication

Architecture requirements:

Use a clean architecture approach:

    presentation
     ├── screens
     ├── widgets
     └── bloc

    domain
     ├── entities
     ├── repositories
     └── usecases

    data
     ├── models
     ├── local database
     ├── remote API
     └── repository implementations

The Flutter app must be maintainable and production-ready.

------------------------------------------------------------------------

## Backend

Use:

-   Java
-   Spring Boot
-   MySQL or PostgreSQL
-   REST API
-   Secure authentication
-   User data isolation

Use proper relational database design.

Do not duplicate customer or site information.

Use relationships:

    User
     |
     +-- Customers
           |
           +-- Sites
                  |
                  +-- Field Notes

Use proper database relationships and JOIN queries when retrieving
related data.

------------------------------------------------------------------------

# Core User Flow

Implement this exact workflow:

## Online Mode

User can:

1.  Register account.
2.  Login.
3.  Create customers.
4.  Add sites under customers.
5.  Create field notes.
6.  Edit existing records.
7.  Delete records.
8.  Search notes.
9.  Filter notes.

------------------------------------------------------------------------

## Offline Mode

The app must continue working without internet.

Users must be able to:

-   Create customers offline.
-   Create sites offline.
-   Create field notes offline.
-   Edit offline data.
-   Delete offline data.

When internet returns:

-   Automatically synchronize local changes.
-   Resolve synchronization conflicts using a clearly defined strategy.
-   Update local storage with server state.

------------------------------------------------------------------------

# Data Models

Implement these entities.

## Customer

Fields:

-   id
-   userId
-   name
-   contactInformation
-   createdAt
-   updatedAt

------------------------------------------------------------------------

## Site

Fields:

-   id
-   customerId
-   siteName
-   address
-   createdAt
-   updatedAt

------------------------------------------------------------------------

## Field Note

Fields:

-   id
-   siteId
-   title
-   description
-   location
-   dateTime
-   status
-   optional photo
-   createdAt
-   updatedAt

------------------------------------------------------------------------

# Application Features

Implement:

## Customer Management

-   Create customer
-   View customers
-   Update customer
-   Delete customer

------------------------------------------------------------------------

## Site Management

-   Create site
-   View sites
-   Update site
-   Delete site

------------------------------------------------------------------------

## Field Note Management

-   Create note
-   Edit note
-   Delete note
-   View notes
-   Search notes

Search must support:

-   Title
-   Description
-   Site
-   Customer

Filtering:

-   Status
-   Site

------------------------------------------------------------------------

# Permissions

Handle properly:

## Location Permission

Required for field note location capture.

Implement:

-   Permission request
-   Permission denied handling
-   User-friendly messages

------------------------------------------------------------------------

## Camera/Gallery Permission

Support optional note photos.

Implement:

-   Camera access
-   Gallery selection
-   Permission handling
-   Image upload synchronization

------------------------------------------------------------------------

# Settings Feature

Create a Settings screen.

Add:

## Default Note Status

Requirements:

-   User selects default status.
-   Save locally.
-   Persist after app restart.
-   Automatically apply when creating a new field note.
-   Do not sync this setting with backend.

------------------------------------------------------------------------

# Authentication

Implement secure authentication.

Requirements:

-   Register API
-   Login API
-   Password hashing
-   Token-based authentication
-   User-specific data isolation

A user must never access another user's:

-   Customers
-   Sites
-   Field notes

------------------------------------------------------------------------

# Backend API Design

Create REST endpoints for:

## Authentication

Example:

    POST /api/auth/register
    POST /api/auth/login

## Customers

    GET    /api/customers
    POST   /api/customers
    PUT    /api/customers/{id}
    DELETE /api/customers/{id}

## Sites

    GET    /api/sites
    POST   /api/sites
    PUT    /api/sites/{id}
    DELETE /api/sites/{id}

## Field Notes

    GET    /api/notes
    POST   /api/notes
    PUT    /api/notes/{id}
    DELETE /api/notes/{id}

Add synchronization endpoints if needed.

------------------------------------------------------------------------

# Offline Synchronization Design

Choose and implement a robust strategy.

Recommended approach:

Each local entity should contain:

    id
    serverId
    syncStatus
    createdAt
    updatedAt
    deleted

Possible sync states:

    PENDING_CREATE
    PENDING_UPDATE
    PENDING_DELETE
    SYNCED

Implement:

1.  Local database first.
2.  Queue offline changes.
3.  Detect connectivity.
4.  Push pending changes.
5.  Pull server updates.
6.  Resolve conflicts.
7.  Mark records synchronized.

------------------------------------------------------------------------

# Database Requirements

Create:

-   Database schema
-   Entity classes
-   Relationships
-   Repositories
-   Services
-   Controllers

Use migrations.

Do not manually create random database state.

------------------------------------------------------------------------

# UI Requirements

The Flutter app should have:

## Screens

-   Splash screen
-   Login screen
-   Register screen
-   Dashboard
-   Customer list
-   Customer details
-   Site list
-   Site details
-   Field note list
-   Field note editor
-   Settings

------------------------------------------------------------------------

# Code Quality Rules

Always:

-   Write clean readable code.
-   Follow SOLID principles.
-   Add comments only where useful.
-   Avoid duplicated logic.
-   Handle errors properly.
-   Validate user input.
-   Use meaningful names.

------------------------------------------------------------------------

# Testing Requirements

Create:

## Backend Tests

Test:

-   Authentication
-   Authorization
-   CRUD operations
-   Database relationships
-   Sync APIs

## Flutter Tests

Test:

-   BLoC logic
-   Local storage
-   Repository layer
-   Important UI flows

------------------------------------------------------------------------

# Documentation

Create:

-   README.md
-   Installation guide
-   Environment configuration guide
-   Database setup instructions
-   API documentation
-   Running instructions

------------------------------------------------------------------------

# Execution Plan

Follow this exact order:

## Phase 1

Environment verification.

## Phase 2

Create backend project.

## Phase 3

Configure database.

## Phase 4

Implement authentication.

## Phase 5

Implement backend entities and APIs.

## Phase 6

Create Flutter application.

## Phase 7

Implement local storage.

## Phase 8

Implement BLoC architecture.

## Phase 9

Implement synchronization.

## Phase 10

Connect mobile app with backend.

## Phase 11

Test everything.

## Phase 12

Fix all issues.

------------------------------------------------------------------------

# Important Final Instruction

Do not provide only explanations.

Actually create the project files.

Actually write the code.

Actually configure dependencies.

Actually run commands.

Actually test the application.

If an error appears:

1.  Diagnose the root cause.
2.  Fix it.
3.  Continue.

The goal is a complete working project, not a tutorial.
