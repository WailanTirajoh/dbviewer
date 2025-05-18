# 👁️ DBViewer

DBViewer is a powerful Rails engine that provides a comprehensive interface to view and explore database tables, records, and schema.
It's designed for development, debugging, and database analysis, offering a clean and intuitive way to interact with your application's database.

<img width="1470" alt="image" src="https://github.com/user-attachments/assets/c946a286-e80a-4cca-afa0-654052e4ef2c" />

## ✨ Features

- **Dashboard**: View a comprehensive dashboard with database analytics, largest tables, most complex tables, and recent SQL queries
- **Table Overview**: View a list of all tables with record count, column count, and quick access links
- **Detailed Schema Information**:
  - View columns with their types, nullability, defaults, and primary key indicators
  - Examine table indexes and their uniqueness constraints
  - Explore foreign key relationships between tables
- **Entity Relationship Diagram (ERD)**:
  - Interactive visualization of database schema and table relationships
  - Zoomable and pannable diagram to explore complex database structures
  - Full table details including all columns and their data types
  - Visual representation of foreign key relationships between tables
- **Data Browsing**:
  - Browse table records with customizable pagination (10, 20, 50, or 100 records per page)
  - Sort data by any column in ascending or descending order
  - Navigate through large datasets with an intuitive pagination interface
  - Scrollable table with fixed headers for improved navigation
  - Single-line cell display with ellipsis for wide content (tooltips on hover)
- **SQL Queries**:
  - Run custom SELECT queries against your database in a secure, read-only environment
  - View table structure reference while writing queries
  - Protection against potentially harmful SQL operations
  - Query execution statistics and timing
- **Enhanced UI Features**:
  - Responsive, Bootstrap-based interface that works on desktop and mobile
  - Fixed header navigation with quick access to all features
  - Modern sidebar layout with improved filtering and scrollable table list
  - Clean tabbed interface for exploring different aspects of table structure
  - Advanced table filtering with keyboard navigation support
  - Proper formatting for various data types (dates, JSON, arrays, etc.)
  - Enhanced data presentation with appropriate styling

## 📸 Screenshots

<details>
  <summary>Click to see more screenshots</summary>
  
  #### Dashboard Overview
  <img width="1470" alt="image" src="https://github.com/user-attachments/assets/4e803d51-9a5b-4c80-bb4c-a761dba15a40" />

#### Table Details

  <img width="1470" alt="image" src="https://github.com/user-attachments/assets/fe425ab4-5b22-4839-87bc-050b80ad4cf0" />

#### Query Editor

  <img width="1470" alt="image" src="https://github.com/user-attachments/assets/392c73c7-0724-4a39-8ffa-8ff5115c5d5f" />

#### Query Logs

  <img width="1470" alt="image" src="https://github.com/user-attachments/assets/7fcf3355-be3c-4d6a-9ab0-811333be5bbc" />

#### ERD

  <img width="1470" alt="image" src="https://github.com/user-attachments/assets/0a2f838f-4ca6-4592-b939-7c7f8ac40f48" />
  
</details>

## 📥 Installation

Add this line to your application's Gemfile:

```ruby
gem "dbviewer", group: :development
```

And then execute:

```bash
$ bundle
```

## 🔧 Usage

Mount the engine in your application's `config/routes.rb` file:

```ruby
Rails.application.routes.draw do
  # Your application routes...

  # Mount the DBViewer engine
  if Rails.env.development?
    mount Dbviewer::Engine, at: "/dbviewer"
  end
end
```

Then, visit `/dbviewer` in your browser to access the database viewer.

### Rails API-only Applications

If you're using a Rails API-only application (created with `--api` flag), you'll need to enable the Flash middleware for DBViewer to work properly. Add the following to your `config/application.rb`:

```ruby
module YourApp
  class Application < Rails::Application
    # ... existing configuration

    # Required for DBViewer flash messages
    config.middleware.use ActionDispatch::Flash
  end
end
```

This is necessary because API-only Rails applications don't include the Flash middleware by default, which DBViewer uses for displaying notifications.

### Available Pages

- **Dashboard** (`/dbviewer`): Comprehensive overview with database statistics and analytics
- **Tables Index** (`/dbviewer/tables`): Shows all tables in your database with column counts and quick access
- **Table Details** (`/dbviewer/tables/:table_name`): Shows table structure and records with pagination
- **SQL Query** (`/dbviewer/tables/:table_name/query`): Allows running custom SQL queries
- **ERD View** (`/dbviewer/entity_relationship_diagrams`): Interactive Entity Relationship Diagram of your database
- **SQL Query Logs** (`/dbviewer/logs`): View and analyze logged SQL queries with performance metrics

## 🤝🏻 Extending DBViewer

### Adding Custom Functionality

You can extend the database manager with custom methods:

```ruby
# config/initializers/dbviewer_extensions.rb
Rails.application.config.to_prepare do
  Dbviewer::DatabaseManager.class_eval do
    def table_statistics(table_name)
      # Your custom code to generate table statistics
      {
        avg_row_size: calculate_avg_row_size(table_name),
        last_updated: last_updated_timestamp(table_name)
      }
    end

    private

    def calculate_avg_row_size(table_name)
      # Implementation...
    end

    def last_updated_timestamp(table_name)
      # Implementation...
    end
  end
end
```

## ⚙️ Configuration Options

You can configure DBViewer by creating an initializer in your application:

```ruby
# config/initializers/dbviewer.rb
Dbviewer.configure do |config|
  config.per_page_options = [10, 20, 50, 100, 250]  # Default pagination options
  config.default_per_page = 20                       # Default records per page
  config.max_query_length = 10000                    # Maximum SQL query length
  config.cache_expiry = 300                          # Cache expiration in seconds
  config.max_records = 10000                         # Maximum records to return in any query
  config.enable_data_export = false                  # Whether to allow data exporting
  config.query_timeout = 30                          # SQL query timeout in seconds

  # Query logging options
  config.query_logging_mode = :memory                # Storage mode for SQL queries (:memory or :file)
  config.query_log_path = "log/dbviewer.log"         # Path for query log file when in :file mode
  config.max_memory_queries = 1000                   # Maximum number of queries to store in memory
end
```

The configuration is accessed through `Dbviewer.configuration` throughout the codebase. You can also access it via `Dbviewer.config` which is an alias for backward compatibility.

## 🪵 Query Logging

DBViewer includes a powerful SQL query logging system that captures and analyzes database queries. You can access this log through the `/dbviewer/logs` endpoint. The logging system offers two storage backends:

### In-Memory Storage (Default)

By default, queries are stored in memory. This provides fast access but queries are lost when the application restarts:

```ruby
config.query_logging_mode = :memory       # Store queries in memory (default)
config.max_memory_queries = 1000          # Maximum number of queries stored
```

### File-Based Storage

For persistent logging across application restarts, you can use file-based storage:

```ruby
config.query_logging_mode = :file         # Store queries in a log file
config.query_log_path = "log/dbviewer.log" # Path where query log file will be stored
```

The file format uses one JSON entry per line, making it easy to analyze with standard tools.

## 🔒 Security Features

DBViewer includes several security features to protect your database:

- **Read-only Mode**: Only SELECT queries are allowed; all data modification operations are blocked
- **SQL Validation**: Prevents potentially harmful operations with comprehensive validation
- **Query Limits**: Automatic LIMIT clause added to prevent excessive data retrieval
- **Pattern Detection**: Detection of SQL injection patterns and suspicious constructs
- **Error Handling**: Informative error messages without exposing sensitive information

## 🌱 Production Access (Not Recommended)

By default, DBViewer only runs in development or test environments for security reasons. If you need to access it in production (not recommended):

1. Set an environment variable with a secure random key:

   ```
   DBVIEWER_PRODUCTION_ACCESS_KEY=your_secure_random_key
   ```

2. Add an additional constraint in your routes:

   ```ruby
   if Rails.env.production?
     constraints ->(req) { req.params[:access_key] == ENV["DBVIEWER_PRODUCTION_ACCESS_KEY"] } do
       mount Dbviewer::Engine, at: "/dbviewer"
     end
   else
     mount Dbviewer::Engine, at: "/dbviewer"
   end
   ```

3. Access the tool with the override parameter:
   ```
   https://yourdomain.com/dbviewer?override_env_check=your_secure_random_key
   ```

## 📝 Security Note

⚠️ **Warning**: This engine is designed for development purposes. It's not recommended to use it in production as it provides direct access to your database contents. If you must use it in production, ensure it's protected behind authentication and use the production access key mechanism with a strong random key.

## 👨‍💻 UI Enhancements

DBViewer includes several UI enhancements for a smoother user experience:

### Dynamic Database Name Display

The sidebar header automatically displays the current database name, making it easier to identify which database you are working with. For databases with long names, the display is automatically truncated with an ellipsis (...), but hovering over the name reveals the full database name in a tooltip.

### Fixed Navigation Header

The top navigation bar remains fixed while scrolling, providing constant access to navigation controls.

### Enhanced Table Filtering

- Real-time filtering of tables in the sidebar
- Keyboard navigation support for accessibility
- Clear indication of filtered results count

### Improved Table Display

- Fixed table headers that remain visible when scrolling through records
- Maximum height for table containers with smooth scrolling
- Single-line cell display with ellipsis for content that exceeds 400px width
- Hover tooltips that display the full content of truncated cells

### Entity Relationship Diagram

The ERD visualization provides several interactive features:

- **Zoom Controls**: Easily zoom in/out with buttons or mouse wheel
- **Panning**: Navigate large diagrams by dragging
- **Reset View**: Quickly return to the default view
- **Dynamic Loading**: Tables and their columns are loaded dynamically for better performance
- **Relationship Lines**: Visual representation of foreign key relationships between tables

### Responsiveness

- Improved sidebar behavior on different screen sizes
- Better spacing and layout for mobile devices
- Optimized element sizing for touch interactions

## 🤌🏻 Contributing

Bug reports and pull requests are welcome.

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
