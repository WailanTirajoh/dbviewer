![dbviewer](https://github.com/user-attachments/assets/665c1a65-aab3-4a7e-aa54-b42e871cb3d0)

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
  - Export table data to CSV format (configurable via `enable_data_export` option)
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
bundle
```

## 🔧 Usage

Mount the engine in your application's `config/routes.rb` file:

```ruby
Rails.application.routes.draw do
  # Your application routes...

  # Mount the DBViewer engine
  mount Dbviewer::Engine, at: "/dbviewer"
  # The engine can be mounted in any environment when using Basic Authentication
end
```

Configure Basic Authentication in an initializer to secure access (strongly recommended):

```ruby
# config/initializers/dbviewer.rb
Dbviewer.configure do |config|
  config.admin_credentials = {
    username: "your_username",
    password: "your_secure_password"
  }
end
```

Then, visit `/dbviewer` in your browser to access the database viewer. You'll be prompted for your username and password.

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

## ⚙️ Configuration Options

You can configure DBViewer by using our generator to create an initializer in your application:

```bash
rails generate dbviewer:initializer
```

This will create a file at `config/initializers/dbviewer.rb` with the default configuration:

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
  config.enable_query_logging = false                # Enable or disable query logging completely (default: true)
  config.query_logging_mode = :memory                # Storage mode for SQL queries (:memory or :file)
  config.query_log_path = "log/dbviewer.log"         # Path for query log file when in :file mode
  config.max_memory_queries = 1000                   # Maximum number of queries to store in memory

  # Authentication options
  # config.admin_credentials = { username: "admin", password: "your_secure_password" } # Basic HTTP auth credentials
end
```

You can also create this file manually if you prefer.

The configuration is accessed through `Dbviewer.configuration` throughout the codebase. You can also access it via `Dbviewer.config` which is an alias for backward compatibility.

## 🪵 Query Logging

DBViewer includes a powerful SQL query logging system that captures and analyzes database queries. You can access this log through the `/dbviewer/logs` endpoint. The logging system offers two storage backends:

### Disabling Query Logging

You can completely disable query logging if you don't need this feature:

```ruby
config.enable_query_logging = false       # Disable query logging completely
```

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
- **HTTP Basic Authentication**: Protect access with username and password authentication

### Basic Authentication

You can enable HTTP Basic Authentication to secure access to DBViewer:

```ruby
Dbviewer.configure do |config|
  config.admin_credentials = {
    username: "your_username",
    password: "your_secure_password"
  }
end
```

When credentials are provided, all DBViewer routes will be protected by HTTP Basic Authentication.
Without valid credentials, users will be prompted for a username and password before they can access any DBViewer page.

## 🌱 Production Access

With the addition of Basic Authentication, DBViewer can now be used in any environment including production. We recommend the following for production deployments:

1. **Always** enable HTTP Basic Authentication with strong credentials:

   ```ruby
   Dbviewer.configure do |config|
     config.admin_credentials = {
       username: "unique_username",
       password: SecureRandom.hex(16)  # Generate a strong random password
     }
   end
   ```

2. Mount the engine in your routes file:

   ```ruby
   # In any environment, with Basic Auth protection
   mount Dbviewer::Engine, at: "/dbviewer"
   ```

3. Access the tool through your regular application URL:

   ```
   https://yourdomain.com/dbviewer?override_env_check=your_secure_random_key
   ```

## 📝 Security Note

⚠️ **Warning**: This engine provides direct access to your database contents, which contains sensitive information. Always protect it with HTTP Basic Authentication by configuring strong credentials as shown above.

When used in production, ensure:

- You use long, randomly generated passwords (e.g., with `SecureRandom.hex(16)`)
- You access DBViewer over HTTPS connections only
- Access is limited to trusted administrators only

## 🔄 Updating DBViewer

To keep DBViewer up to date with the latest features, security patches, and bug fixes, follow these steps:

### Using Bundler

The simplest way to update is using Bundler:

- Update your Gemfile with the desired version:

  ```ruby
  # For the latest version
  gem "dbviewer", group: :development

  # Or specify a version
  gem "dbviewer", "~> 0.3.2", group: :development
  ```

- Run bundle update:

  ```ruby
  bundle update dbviewer
  ```

- Restart your Rails server to apply the changes:

  ```ruby
  rails server
  ```

## 🤌🏻 Contributing

Bug reports and pull requests are welcome.

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
