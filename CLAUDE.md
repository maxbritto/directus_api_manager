# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dart package for communicating with a Directus server via its REST API. Provides type-safe CRUD operations, authentication, WebSocket subscriptions, caching, filtering, and file management.

## Commands

```bash
# Run all tests
dart test

# Run a single test file
dart test test/filter_test.dart

# Run tests matching a name pattern
dart test -n "PropertyFilter"

# Lint / static analysis
dart analyze

# Code generation (required after modifying @DirectusCollection models)
dart run build_runner build

# Get dependencies
dart pub get
```

## Architecture

### Core Layers

- **`IDirectusApiManager`** (`src/idirectus_api_manager.dart`) — Public interface defining all API operations
- **`DirectusApiManager`** (`src/directus_api_manager_base.dart`) — Main implementation. Orchestrates HTTP requests, caching, token management, and WebSocket connections
- **`IDirectusAPI` / `DirectusAPI`** (`src/directus_api.dart`) — Internal layer that builds HTTP requests and parses responses. Manages access/refresh tokens

### Data Model Hierarchy

- **`DirectusData`** (`src/model/directus_data.dart`) — Abstract base. Stores raw server data in `_rawReceivedData` and tracks mutations in `updatedProperties`. Only changed fields are sent on update
- **`DirectusItem`** extends `DirectusData` — Base for user-defined collection models
- **`DirectusUser`**, **`DirectusFile`** — Built-in Directus types that extend `DirectusData`

### Reflection / Code Generation

Models are annotated with `@DirectusCollection()` and `@CollectionMetadata(endpointName:, ...)`. At runtime, `MetadataGenerator` uses `reflectable` to discover annotated classes and instantiate them from JSON. After changing model annotations, run `dart run build_runner build` to regenerate `.reflectable.dart` files.

### Request Pipeline (`_sendRequest`)

Central method in `DirectusApiManager` that handles: token refresh (mutex-protected) → cache check → HTTP send → cache save → fallback to stale cache on error → parse response.

### Caching

Optional pluggable cache via `ILocalDirectusCacheInterface`. Two implementations: `MemoryCacheEngine` (in-memory) and `JsonCacheEngine` (file-persisted). Cache entries are tagged for bulk invalidation (e.g., invalidate all list caches for a collection on write).

### Filtering

`PropertyFilter`, `LogicalOperatorFilter`, `RelationFilter`, `GeoFilter` — compose into Directus-compatible JSON filter syntax. `GeoJsonPolygon` supports geospatial queries.

### WebSocket

`DirectusWebSocket` manages connection lifecycle with auto-ping and token refresh. `DirectusWebSocketSubscription<T>` provides typed callbacks for create/update/delete events.

## Testing Patterns

- Tests use Dart's `test` package with `group()`/`test()`/`setUp()`
- Custom mock classes in `test/mock/` — `MockHTTPClient`, `MockDirectusApi` — use a queue pattern (`addNextReturnFutureObject` / `popNextReturnedObject`) to simulate responses
- `MockCacheEngine` in `lib/test/` for cache testing
- Tests requiring reflection must import and call `initializeReflectable()` from the corresponding `.reflectable.dart` file
- Mock utilities are also exported from `lib/test/` for consumers to use in their own tests

## Key Files

| File | Purpose |
|------|---------|
| `lib/directus_api_manager.dart` | Library barrel file (all public exports) |
| `lib/src/directus_api_manager_base.dart` | Main `DirectusApiManager` class (~900 lines) |
| `lib/src/directus_api.dart` | Internal HTTP/token layer |
| `lib/src/model/directus_data.dart` | Base data class with change tracking |
| `lib/src/filter.dart` | All filter types |
| `lib/src/annotations.dart` | `@DirectusCollection` and `@CollectionMetadata` |
| `lib/src/metadata_generator.dart` | Reflectable-based type instantiation |
| `test/directus_api_manager_base_test.dart` | Main integration test suite |
