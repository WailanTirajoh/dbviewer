# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Configuration system with customizable settings
- Table metadata display with indexes and foreign keys
- Enhanced SQL validation with more security checks
- Table structure reference in SQL query view
- Performance improvements with caching for table metadata
- Better error handling throughout the application
- Support for custom styling and extensions

### Changed

- Moved database and SQL validation logic to dedicated services
- Refactored controllers for better organization and maintainability
- Enhanced the UI with tabbed interface for table details
- Updated SQL query execution with timing and statistics
- Improved documentation with configuration options and examples

### Fixed

- Database loading issues with proper connection handling
- Raw SQL queries replaced with ActiveRecord best practices
- Asset pipeline compatibility with conditional checks
- Per-page setting persistence during navigation

## [1.0.0] - 2025-04-15

### Added

- Initial release with basic functionality
- Table listing and record viewing
- Simple SQL query interface
- Pagination for record viewing
- Column sorting capabilities
- Basic documentation
