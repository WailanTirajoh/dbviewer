# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1] - 2025-05-17

### Added

- **Database name display** in the sidebar header for better database identification
  - Automatically truncates long database names with an ellipsis
  - Tooltip on hover shows the full database name
  - Responsive design for all screen sizes

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
