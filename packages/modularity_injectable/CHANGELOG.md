## 0.2.0

- `GetItBinder` and `ModularityInjectableBridge` now throw typed exceptions from
  `modularity_contracts` instead of generic errors.
- Added comprehensive dartdoc coverage on all public APIs.
- Added strict `analysis_options.yaml` (strict-casts, strict-inference, strict-raw-types).

## 0.1.1

- Added `BinderGetIt` proxy to resolve dependencies through Modularity rules (local/imports/parent) from inside injectable-generated factories.
- Updated `ModularityInjectableBridge` to use `BinderGetIt` for both internal and export configuration.

## 0.1.0

- Updated dependencies to modularity_contracts ^0.1.0 and modularity_core ^0.1.0.

## 0.0.2

- Updated dependencies to modularity_contracts ^0.0.2 and modularity_core ^0.0.2
- Improved package metadata for pub.dev

## 0.0.1

- Initial release
- `GetItBinder` — Binder implementation backed by scoped GetIt instances
- `GetItBinderFactory` — factory for creating GetItBinder instances
- `ModularityInjectableBridge` — helper to invoke injectable-generated functions
- `modularityExportEnv` — environment constant for marking exported dependencies
- `ModularityExportOnly` — environment filter for selective exports
