# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.5] - 2025-05-20

### Added

- **HTTP Basic Authentication** support for securing access to DBViewer routes
  - Configuration option for setting admin username and password credentials
  - Secure username and password verification with constant-time comparison
  - Documentation in README for setup and configuration

### Changed

- Removed environment restrictions (development/test only)
  - DBViewer can now run in any environment when protected by authentication
  - Updated documentation to reflect new security model
  - Updated usage instructions for mounting in production environments

## [0.3.4] - 2025-05-19

### Added

- **Enhanced SQL editor** in the query interface
  - Integrated Monaco Editor with SQL syntax highlighting
  - Smart SQL auto-completion with table and column names
  - Interactive example queries based on table structure
  - Keyboard shortcuts for common SQL operations
  - Status bar with position and table information
  - Proper handling of quoted text in SQL queries
  - Collapsible table structure reference for cleaner interface
- **Dark mode support** for improved readability and reduced eye strain
  - Toggle button in the navigation bar with smooth transition animation
  - Remembers user preference with localStorage
  - Automatic detection of system preference
  - Monaco editor theme changes dynamically
  - Optimized UI elements for both light and dark modes
  - Smooth theme transitions and improved color contrast
  - Dark-optimized tables, forms, and code displays
  - Enhanced database overview dashboard with theme-aware stats cards
  - Improved SQL query highlighting for dark theme
  - Better visual hierarchy and readability in all views
  - Theme-adaptive tables with proper styling in both light and dark modes
  - Dynamic chart colors that respond to theme changes
  - Enhanced code blocks in the logs view for dark theme consistency
  - Consistent styling for list groups and modal dialogs
  - Improved link colors for better visibility in dark mode

### Changed

- Renamed `DatabasesController` to `TablesController` for better semantic clarity
  - Updated all related routes and path helpers
  - View templates moved to tables/ directory

### Fixed

- Fixed SQLite schema size calculation with proper handling of PRAGMA commands
  - Added specialized execution method for SQLite PRAGMA statements
  - Prevented LIMIT clause from being added to PRAGMA commands
  - Enhanced SQL validator to recognize safe PRAGMA statements

## [0.3.1] - 2025-05-17

### Added

- **Database name display** in the sidebar header for better database identification
  - Automatically truncates long database names with an ellipsis
  - Tooltip on hover shows the full database name
  - Responsive design for all screen sizes
- **Dedicated Dashboard/Homepage** separate from tables listing
  - Database analytics with key statistics
  - Overview of largest and most complex tables
  - Recent SQL queries display
  - Improved navigation between features

### Changed

- **Refactored QueryLogger** for better maintainability and performance
  - Split into separate classes with single responsibilities
  - Improved test coverage and documentation
  - Better organization and cleaner code structure

## [0.3.0] - 2025-05-14

- **Database Analytics Dashboard** with visual insights into database structure
- Statistics showing total records, columns, and database size
- Charts displaying largest tables by record count and column count
- Empty tables identification and listing
- **Record creation timeline visualization** with hourly, daily, and weekly views
- **Export to CSV functionality** for database tables with configurable options
- **ERD download functionality** to save diagrams as SVG or PNG files
- **SQL Query Logs** page to monitor and debug database queries
  - Request-based grouping to identify related queries
  - Automatic N+1 query detection with optimization suggestions
  - Top 5 slowest queries dashboard for quick performance analysis
  - Collapsible performance sections (N+1 and slowest queries) to reduce visual clutter
  - Comprehensive query filtering and analysis tools
  - Filter-aware statistics that update based on applied filters
  - Automatic filtering of internal DBViewer queries to show only application queries
- Persistent table search functionality with localStorage
- Improved controller code organization with concerns

### Changed

- Redesigned homepage with analytics focus instead of just table listings
- Improved table detail UI with two-column layout for structure and timeline visualization
- Refactored controller code for better maintainability
- Simplified JavaScript code with inline implementation
- Moved Chart.js to layout template for better performance and code reuse
- Improved sidebar search with real-time filtering
- Enhanced table structure display with tabs and better visual hierarchy
- Optimized sidebar performance by removing record counts

## [0.2.0] - 2025-05-17

### Added

- **Entity Relationship Diagram (ERD)** visualization of database schema
- Fixed header navigation with improved accessibility
- Interactive zooming and panning for the ERD viewer
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
- Redesigned the interface with a persistent sidebar for table navigation
- Improved sidebar with better filtering and keyboard navigation
- Added scrollable table containers with fixed headers
- Implemented single-line table cells with ellipsis and tooltips for wide content
- Updated SQL query execution with timing and statistics
- Improved documentation with configuration options and examples

### Fixed

- Database loading issues with proper connection handling
- Sidebar filter search correctly updating filtered results count
- Improved layout with proper spacing for fixed navigation
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

## Unreleased

### Added

- Dark mode support throughout the application
  - Toggle feature in the navbar with localStorage persistence
  - System preference detection via `prefers-color-scheme`
  - Monaco editor theme switching for SQL queries
  - Theme-adaptive styling for all UI components including tables, forms, cards
  - Dark mode compatible SQL log display and charts
  - Improved chart visualization with dark/light theme detection
