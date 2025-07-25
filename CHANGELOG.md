# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.4] - 2025-07-06

### Added

- **Full CRUD Operations**
  - Completed the implementation of Create, Read, Update, Delete operations for database records
  - Enhanced user interface with intuitive controls for all record operations
  - Added configuration options to enable/disable specific operations:
    - `enable_record_creation` for creating new records
    - `enable_record_editing` for updating existing records
    - `enable_record_deletion` for removing records

## [0.9.4-alpha.3] - 2025-07-06

### Added

- **Record Editing Feature**
  - Added ability to edit records directly from the table interface
  - Implemented edit buttons in both table rows and record detail modal
  - Added AJAX-based form loading and submission for record editing
  - Added toast notifications for edit success/failure
  - Added `enable_record_editing` configuration option (enabled by default)
  - Integrated field-specific inputs with Select2 and Flatpickr for improved UX

## [0.9.4-alpha.2] - 2025-07-06

### Added

- **Record Deletion Feature**
  - Added ability to delete records directly from the table interface
  - Implemented deletion buttons in both table rows and record detail modal
  - Added confirmation dialog with record information before deletion
  - Added toast notifications for deletion success/failure
  - Added `enable_record_deletion` configuration option (enabled by default)

## [0.9.4-alpha.1] - 2025-07-05

### Added

- **Record Creation Feature**
  - Added ability to create new records directly from the database viewer interface
  - Implemented floating "Add Record" button and modal for record creation
  - Added AJAX-based form loading and submission for record creation
  - Added `enable_record_creation` configuration option (enabled by default)
  - Integrated Select2 for searchable dropdowns in forms with dark mode support

### Enhanced

- **UI Improvements**
  - Improved error handling and user feedback during record creation
  - Added inline field errors and toast notifications
  - Enhanced form styling with better user experience

### Backend Changes

- Added `new_record` and `create_record` actions in `TablesController`
- Updated routing to include endpoints for new record creation
- Added database schema validation and metadata integration

## [0.9.0] - 2025-06-27

### Added

- **Robust Table-Level Access Control System**

  - Configurable access control modes: `:none`, `:whitelist`, `:blacklist`
  - `allowed_tables` and `blocked_tables` configuration options
  - Column-level access control with `blocked_columns` configuration
  - SQL query validation to prevent unauthorized table access
  - Integration across UI, API endpoints, and Entity Relationship Diagrams
  - Optimized filtering to occur before expensive database queries

- **Advanced SQL Parser for Security Validation**

  - Dedicated `Dbviewer::Security::SqlParser` class for maintainability
  - Comprehensive SQL parsing supporting CTEs, subqueries, joins, and DML operations
  - Enhanced string literal handling to preserve comment-like content in strings
  - Improved CTE name detection supporting quoted and schema-qualified identifiers
  - Robust comment removal that respects string boundaries
  - Extensive test coverage with 40+ test cases

- **Enhanced Security Features**
  - Access control validation in all controllers and API endpoints
  - ERD filtering to show only accessible tables and relationships
  - Proper error handling with informative access violation messages
  - Performance optimizations for large database schemas

### Improved

- **SQL Comment Processing**: Fixed regex-based comment removal to properly handle string literals
- **CTE Detection**: Enhanced regex to support quoted identifiers (`"name"`, `` `name` ``) and schema-qualified names
- **Code Organization**: Refactored large methods into dedicated, testable classes
- **Documentation**: Comprehensive documentation for SQL parser improvements and access control

### Technical Details

- Moved SQL parsing logic from `AccessControl` private methods into `SqlParser` class (~250 lines refactored)
- Implemented character-by-character parser for accurate string literal detection
- Added support for escaped quotes and complex SQL constructs
- Enhanced CTE filtering to exclude CTE names from table extraction results
- Created extensive test suites for both unit and integration testing

## [0.8.0] - 2025-06-26

### Added

- **PII Data Masking**: Comprehensive PII (Personally Identifiable Information) masking system
  - Built-in masking types: `:email`, `:phone`, `:ssn`, `:credit_card`, `:full_redact`, `:partial`
  - Custom masking support with lambda/proc functions
  - Reusable custom mask definitions
  - Column-specific masking rules using `table.column` format
  - Global enable/disable functionality
  - Applied to table views, query results, and detail modals
  - Comprehensive test coverage and documentation
- Added `Dbviewer.configure_pii` method for easy PII rule configuration
- Added PII configuration example generator
- Added detailed PII masking documentation

## [0.4.5] - 2025-05-25

### Added

- Added Rails generator `dbviewer:install` to create configuration file
- Updated documentation to include the new generator usage information
- Enhanced engine to properly load generators

## [0.3.15] - 2025-05-22

### Enhanced

- Made Mini ERD diagram render at full width and height of the modal window
- Added responsive resizing for better diagram viewing experience
- Improved SVG-Pan-Zoom configuration with better zoom limits and controls
- Added automatic resizing of the diagram when the modal is resized
- Removed padding in modal body for maximum diagram space
- Increased minimum height of diagram to 450px for better visibility
- Added proper SVG viewBox configuration for better scaling
- Changed modal dialog from modal-lg to modal-xl for more viewing space

### Fixed

- Modified Mini ERD to refresh data every time the modal is opened instead of using cached data
- Added cache-busting to ensure fresh ERD data is fetched from the server
- Cleared cached diagram data when the modal is closed

## [0.3.14] - 2025-05-22

### Fixed

- Fixed issue where the Mini ERD displayed raw JSON data instead of rendering the diagram
- Moved Mermaid.js rendering logic to the table show page instead of the AJAX-loaded template
- Improved data handling by using JSON endpoint instead of HTML for relationship data
- Enhanced caching of relationship data to avoid redundant API calls
- Simplified Mini ERD template to strictly contain HTML without JavaScript

## [0.3.13] - 2025-05-22

### Fixed

- Fixed critical issue where raw JSON was displayed instead of the rendered ERD diagram
- Completely revised JavaScript rendering to ensure diagram appears properly
- Added debug information for easier troubleshooting
- Improved error handling for malformed relationship data

## [0.3.12] - 2025-05-22

### Fixed

- Fixed issue where the Mini ERD diagram wasn't displaying after loading data
- Enhanced error handling and reporting in Mini ERD functionality
- Improved reliability of relationship detection and display
- Added timeout handling and retry functionality for Mini ERD

## [0.3.11] - 2025-05-22

### Added

- Added Mini ERD feature to table detail pages
- New "View Relationships" button for quick access to table relationships
- Interactive visualization of foreign key connections for the current table
- Enhanced understanding of database structure with focused relationship diagrams

## [0.3.10] - 2025-05-22

### Added

- Added icons to metric cards on the homepage for improved visual experience
- Enhanced UI with visual indicators for different database metrics
- Improved card layout with icons on the left and content on the right for better readability
- Added subtle shadows to metric cards for visual hierarchy and depth

## [0.3.9] - 2025-05-22

### Changed

- Replaced "Columns" card on dashboard with "Relationships" card showing foreign key connections
- Added relationship counting to database analytics
- Improved dashboard visualization of database relationships

## [0.3.8] - 2025-05-22

### Fixed

- Fixed "undefined method 'columns' for nil:NilClass" error when filters return no records
- Improved error handling in tables view to gracefully handle edge cases
- Added defensive programming checks to prevent nil errors in table display

## [0.3.7] - 2025-05-22

### Added

- **Foreign Key Navigation** in table records view
  - Clickable foreign key cells to navigate directly to referenced records
  - Visual indication of foreign key relationships with link icon
  - Automatic filtering of target table to show only the referenced record

## [0.3.6] - 2025-05-22

### Added

- **Optional Query Logging** feature for improved control
  - New `enable_query_logging` configuration option to completely disable SQL query logging
  - Skip query capture at the source for better performance when logging is disabled
  - User-friendly UI messages when query logging is disabled
  - Intelligent redirection when attempting to access logs with logging disabled
  - Comprehensive documentation in README for the new setting
- **Data Export Configuration** enforced throughout the application
  - Improved handling of the `enable_data_export` configuration option
  - Export UI elements now conditionally rendered based on configuration
  - Server-side validation to prevent unauthorized data exports
  - Updated documentation in README for data export capabilities

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
