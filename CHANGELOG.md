# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2021-08-18

### Added

- Rails lifecycle hooks: `before_sanitization` and `after_sanitization`.
- Support for custom model sanitizers using `sanitizes_with`.
- Support for custom field sanitizers through classes that implement a `sanitizes_each` method.

### Changed

- Sanitization is now specified on a per-field basis and follow the same patterns as ActiveRecord::Validations.
- Renamed `collapse` to `squish` to better match convention.

### Removed

- Initializer/Configuration. Sanitization is not configured at a global level.
- Support for `only` and `except` keywords.
- Removed `sanitization` method to better follow convention.

## [1.1.1] - 2021-05-06

### Changed

- `sanitization` method to `sanitizes` as the new preferred way. `sanitization` still works and is an alias of `sanitizes`.

## [1.1.0] - 2021-05-06

### Added

- Support for configuration block.

### Changed

- **BREAKING CHANGE:** By default, Sanitization now does nothing. A configuration block should be used to set your desired defaults. Add `Sanitization.simple_defaults!` to `config/initializers/sanitization.rb` for version 1.0.x defaults.

## [1.0.0] - 2021-05-03

- Initial Release

[2.0.0]: https://github.com/dansteren/sanitization/compare/v1.1.1...v2.0.0
[1.1.1]: https://github.com/dansteren/sanitization/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/dansteren/sanitization/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/dansteren/sanitization/releases/tag/v1.0.0
