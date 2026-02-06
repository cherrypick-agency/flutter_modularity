## 0.2.0

- Widgets and retention logic now throw typed exceptions from `modularity_contracts`
  instead of generic errors.
- Added comprehensive dartdoc coverage on all public APIs.
- Added strict `analysis_options.yaml` (strict-casts, strict-inference, strict-raw-types).

## 0.1.0

### Retention Policies
- `ModuleScope` gained `retentionPolicy`/`retentionKey`/`retentionExtras`
  support plus the new `overrideScope` parameter for child override trees.
- Formal `ModuleRetentionPolicy` enum: `strict`, `routeBound`, `keepAlive`.
- Pluggable retention strategies with route-aware lifecycle management.
- `KeepAlive` modules now correctly dispose when owning route terminates.

### Lifecycle Logging
- Added `ModuleLifecycleEvent` enum and `ModuleLifecycleLogger` callback.
- New `Modularity.enableDebugLogging()` for console output in debug builds.
- Events: `created`, `reused`, `registered`, `disposed`, `evicted`, `released`,
  `routeTerminated`.

### Documentation
- Documented `retentionKey` vs `overrideScope` contract in `ModuleScope` and
  `ModuleRetainer` doc comments.
- Updated README with lifecycle logging and retention contract examples.

## 0.0.2

- Updated dependencies to modularity_contracts ^0.0.2 and modularity_core ^0.0.2
- Improved package metadata for pub.dev (topics, issue_tracker)

## 0.0.1

- Initial release.
