## 0.0.3

- `GetItBinder` now implements `RegistrationAwareBinder` and preserves resolved
  singletons while refreshing factories during hot reload / overrides.
- Added tests covering the new behavior.

## 0.0.2

- Implemented `sealPublicScope()` and `resetPublicScope()` in `GetItBinder`
- Added `isExportModeEnabled` and `isPublicScopeSealed` getters
- Updated dependencies to modularity_contracts ^0.0.2
- Improved README with detailed documentation and examples
- Improved package metadata for pub.dev (topics, issue_tracker)

## 0.0.1

- Initial release.
