![dbviewer](https://github.com/user-attachments/assets/665c1a65-aab3-4a7e-aa54-b42e871cb3d0)

# 👁️ DBViewer

DBViewer is a powerful Rails engine that provides a comprehensive interface to view and explore database tables, records, and schema.
It's designed for development, debugging, and database analysis, offering a clean and intuitive way to interact with your application's database.

<img width="1470" alt="image" src="https://github.com/user-attachments/assets/0d2719ad-f5b4-4818-891d-5bff7be6c5c3" />

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
- **Multiple Database Connections**:
  - Connect to multiple databases within your application
  - Switch between connections on-the-fly to view different database schemas
  - Add new database connections from the UI without code changes
  - Test connections to verify they're working properly
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

  <img width="1470" alt="image" src="https://github.com/user-attachments/assets/7d708c14-5f78-42c4-b769-2167546b3aad" />
  <img width="1470" alt="image" src="https://github.com/user-attachments/assets/f6d9a39a-a571-4328-908a-d96b3148f707" />

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

## ⚙️ Configuration Options

You can configure DBViewer by using our generator to create an initializer in your application:

```bash
rails generate dbviewer:install
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

### Multiple Database Connections

DBViewer supports working with multiple database connections in your application. This is useful for applications that connect to multiple databases or use different connection pools.

To configure multiple database connections, set them up in your initializer:

```ruby
# config/initializers/dbviewer.rb
Dbviewer.configure do |config|
  # Multiple database connections configuration
  config.database_connections = {
    primary: { 
      connection_class: "ActiveRecord::Base",
      name: "Primary Database" 
    },
    secondary: { 
      connection_class: "SecondaryDatabase",
      name: "Blog Database" 
    }
  }
  
  # Set the default active connection
  config.current_connection = :primary
end
```

Each connection needs to reference an ActiveRecord class that establishes a database connection. For more details, see [Multiple Database Connections](docs/multiple_connections.md).

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

The file format uses one JSON entry per line, making it easy to analyze with standard tools. Query Log collector are disabled by default on non development environtment.

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
   https://yourdomain.com/dbviewer
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

## 🛠️ Development Setup

To set up the development environment for contributing to DBViewer:

### Quick Setup

Run the setup script to automatically configure your development environment:

```bash
bin/setup
```

This script will:

- Install bundler and gem dependencies
- Set up the test dummy Rails application
- Create and seed the development database
- Prepare the test environment
- Clean up old logs and temporary files

### Manual Setup

If you prefer to set up manually:

```bash
# Install dependencies
bundle install

# Set up the dummy app database
cd test/dummy
bin/rails db:prepare
bin/rails db:migrate
bin/rails db:seed
cd ../..

# Prepare test environment
cd test/dummy && bin/rails db:test:prepare && cd ../..
```

### Development Commands

```bash
# Start the development server
cd test/dummy && bin/rails server

# Run tests
bundle exec rspec

# Run code quality checks
bin/rubocop

# Open an interactive console
bin/console

# Build the gem
gem build dbviewer.gemspec
```

### Testing Your Changes

1. Start the dummy Rails application: `cd test/dummy && bin/rails server`
2. Visit `http://localhost:3000/dbviewer` to test your changes
3. The dummy app includes sample data across multiple tables to test various DBViewer features

### Architecture Diagram

```mermaid
graph TB
    subgraph "DBViewer Engine"
        Engine[Engine<br/>Rails::Engine]
        Config[Configuration<br/>Settings & Defaults]
        SqlValidator[SqlValidator<br/>Query Validation]
    end

    subgraph "Controllers Layer"
        HomeController[HomeController<br/>Dashboard & Overview]
        TablesController[TablesController<br/>Table Operations]
        LogsController[LogsController<br/>Query Logs]
        ERDController[ERDController<br/>Entity Relationships]
        APIController[API Controllers<br/>JSON Endpoints]
    end

    subgraph "Database Namespace"
        Manager[Manager<br/>Database Operations]
        CacheManager[CacheManager<br/>Caching Layer]
        MetadataManager[MetadataManager<br/>Schema Information]
        DynamicModelFactory[DynamicModelFactory<br/>ActiveRecord Models]
    end

    subgraph "Query Namespace"
        QueryExecutor[Executor<br/>SQL Execution]
        QueryLogger[Logger<br/>Query Logging]
        QueryAnalyzer[Analyzer<br/>Performance Analysis]
        QueryParser[Parser<br/>SQL Parsing]
    end

    subgraph "Datatable Namespace"
        QueryOperations[QueryOperations<br/>Table Queries]
        QueryParams[QueryParams<br/>Parameter Handling]
    end

    subgraph "Storage Namespace"
        StorageBase[Base<br/>Storage Interface]
        InMemoryStorage[InMemoryStorage<br/>Memory Storage]
        FileStorage[FileStorage<br/>File Storage]
    end

    %% Configuration Dependencies (Decoupled)
    Config -.->|"Dependency Injection"| Manager
    Manager -->|"cache_expiry"| CacheManager
    Manager -->|"config object"| QueryExecutor

    %% Main Dependencies
    Engine --> HomeController
    Engine --> TablesController
    Engine --> LogsController
    Engine --> ERDController

    Manager --> CacheManager
    Manager --> MetadataManager
    Manager --> DynamicModelFactory
    Manager --> QueryOperations

    CacheManager --> DynamicModelFactory
    CacheManager --> MetadataManager

    QueryOperations --> DynamicModelFactory
    QueryOperations --> QueryExecutor
    QueryOperations --> MetadataManager

    QueryLogger --> StorageBase
    StorageBase --> InMemoryStorage
    StorageBase --> FileStorage

    TablesController --> Manager
    HomeController --> Manager
    LogsController --> QueryLogger
    APIController --> Manager
    APIController --> QueryLogger

    %% Decoupled Configuration Flow
    Engine -.->|"setup()"| QueryLogger
    Config -.->|"logging settings"| QueryLogger

    class CacheManager,QueryLogger decoupled
    class HomeController,TablesController,LogsController,ERDController,APIController controller
    class Manager,MetadataManager,DynamicModelFactory database
    class QueryExecutor,QueryAnalyzer,QueryParser query
    class StorageBase,InMemoryStorage,FileStorage storage
```

## 🤌🏻 Contributing

Bug reports and pull requests are welcome.

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
