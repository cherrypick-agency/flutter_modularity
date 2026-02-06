## 0.2.0

- Added typed exception hierarchy: `ModularityException`, `DependencyNotFoundException`,
  `CircularDependencyException`, `ModuleConfigurationException`, `ModuleLifecycleException`.
- Added comprehensive dartdoc coverage on all public APIs.
- Added strict `analysis_options.yaml` (strict-casts, strict-inference, strict-raw-types).
- Migrated to native Dart workspaces (from melos).

## 0.1.0

- Added `RegistrationStrategy` and `RegistrationAwareBinder` so containers can
  control how re-registrations behave (used for hot reload / overrides).
- Added `ModuleRetentionPolicy` enum (`strict`, `routeBound`, `keepAlive`).

## 0.0.2

- Added `sealPublicScope()` and `resetPublicScope()` to `ExportableBinder`
- Added `isExportModeEnabled` and `isPublicScopeSealed` getters
- Improved package metadata for pub.dev (topics, issue_tracker, description)

## 0.0.1

- Initial release.
