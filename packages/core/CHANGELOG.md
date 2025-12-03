## 0.0.3

- Added `ModuleOverrideScope` for hierarchical overrides and exported it via
  `modularity_core`.
- `ModuleController.hotReload` now preserves singleton instances while
  refreshing factories and re-applies overrides automatically (uses the new
  `RegistrationStrategy.preserveExisting`).
- `SimpleBinder` implements `RegistrationAwareBinder` and respects preserve mode
  for both private and public scopes.
- `GraphResolver` and `ModuleController` now pass override scopes down to child
  modules.

## 0.0.2

- Implemented `sealPublicScope()` and `resetPublicScope()` in `SimpleBinder`
- Added `isExportModeEnabled` and `isPublicScopeSealed` getters
- Improved README with detailed documentation and examples
- Improved package metadata for pub.dev (topics, issue_tracker)

## 0.0.1

- Initial release.
