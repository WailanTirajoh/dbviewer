# 👁️ DBViewer

> **The fastest way to visualize and explore your database**

DBViewer is a powerful Rails engine that provides a comprehensive interface to view and explore database tables, records, and schema.
It's designed for development, debugging, and database analysis, offering a clean and intuitive way to interact with your application's database.

<img width="1470" alt="image" src="https://github.com/user-attachments/assets/6bc68cfa-903e-49fb-a450-425317d6cbc0" />

## ✨ Features

- **Dashboard**
- **Table Overview**
- **Detailed Schema Information**
- **Entity Relationship Diagram (ERD)**
- **Data Browsing**
- **SQL Queries**
- **Multiple Database Connections**
- **PII Data Masking** - Protect sensitive data with configurable masking rules
- **Enhanced UI Features**

## 🧪 Demo Application

You can explore a live demo of DBViewer at [https://dbviewer-demo.wailantirajoh.tech/](https://dbviewer-demo.wailantirajoh.tech/). This demo showcases all the features of DBViewer on a sample database, allowing you to try out the tool before installing it in your own application.

## 📥 Installation

Add this line to your application's Gemfile:

```ruby
gem "dbviewer"
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

  # Table and Column Access Control
  # config.access_control_mode = :whitelist  # :whitelist, :blacklist, or :none (default)
  # config.allowed_tables = ['users', 'orders', 'products']  # Only these tables accessible (whitelist mode)
  # config.blocked_tables = ['admin_users', 'sensitive_data']  # These tables blocked (blacklist mode)
  # config.blocked_columns = {  # Hide sensitive columns from specific tables
  #   'users' => ['password_digest', 'api_key', 'secret_token'],
  #   'orders' => ['internal_notes']
  # }

  # Disable DBViewer completely
  # config.disabled = Rails.env.production?  # Disable in production
end
```

You can also create this file manually if you prefer.

The configuration is accessed through `Dbviewer.configuration` throughout the codebase. You can also access it via `Dbviewer.config` which is an alias for backward compatibility.

### Disabling DBViewer Completely

You can completely disable DBViewer access by setting the `disabled` configuration option to `true`. When disabled, all DBViewer routes will return 404 (Not Found) responses:

```ruby
# config/initializers/dbviewer.rb
Dbviewer.configure do |config|
  # Completely disable DBViewer in production
  config.disabled = Rails.env.production?

  # Or disable unconditionally
  # config.disabled = true
end
```

This is useful for:

- **Production environments** where you want to completely disable access to database viewing tools
- **Security compliance** where database admin tools must be disabled in certain environments
- **Performance** where you want to eliminate any potential overhead from DBViewer routes

When disabled:

- All DBViewer routes return 404 (Not Found) responses
- No database connections are validated
- No DBViewer middleware or concerns are executed
- The application behaves as if DBViewer was never mounted

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

Each connection needs to reference an ActiveRecord class that establishes a database connection.

## 🪵 Query Logging (Development Only)

DBViewer includes a powerful SQL query logging system that captures and analyzes database queries. You can access this log through the `/dbviewer/logs` endpoint.

The logging system offers two storage backends:

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
- **Complete Disabling**: Completely disable DBViewer in production or sensitive environments

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

### Complete Disabling

For maximum security in production environments, you can completely disable DBViewer:

```ruby
Dbviewer.configure do |config|
  # Completely disable DBViewer in production
  config.disabled = Rails.env.production?
end
```

When disabled, all DBViewer routes return 404 responses, making it appear as if the tool was never installed. This is the recommended approach for production systems where database admin tools should not be accessible.

### 🔐 PII Data Masking

DBViewer includes built-in support for masking Personally Identifiable Information (PII) to protect sensitive data while allowing developers to browse database contents.

#### Quick Setup

Configure PII masking in your Rails initializer (e.g., `config/initializers/dbviewer.rb`):

```ruby
# Enable PII masking (enabled by default)
Dbviewer.configure do |config|
  config.enable_pii_masking = true
end

# Define masking rules
Dbviewer.configure_pii do |pii|
  # Built-in masking types
  pii.mask 'users.email', with: :email           # john@example.com → jo***@example.com
  pii.mask 'users.phone', with: :phone           # +1234567890 → +1***90
  pii.mask 'users.ssn', with: :ssn               # 123456789 → ***-**-6789
  pii.mask 'payments.card_number', with: :credit_card  # 1234567890123456 → ****-****-****-3456
  pii.mask 'users.api_key', with: :full_redact   # any_value → ***REDACTED***

  # Custom masking with lambda
  pii.mask 'users.salary', with: ->(value) { value ? '$***,***' : value }

  # Define reusable custom masks
  pii.custom_mask :ip_mask, ->(value) {
    return value if value.nil?
    parts = value.split('.')
    "#{parts[0]}.#{parts[1]}.***.***.***"
  }
  pii.mask 'logs.ip_address', with: :ip_mask
end
```

#### Built-in Masking Types

- **`:email`** - Masks email addresses while preserving domain
- **`:phone`** - Masks phone numbers keeping first and last digits
- **`:ssn`** - Masks Social Security Numbers showing only last 4 digits
- **`:credit_card`** - Masks credit card numbers showing only last 4 digits
- **`:full_redact`** - Completely redacts the value
- **`:partial`** - Partial masking (default behavior)

### Table and Column Access Control

DBViewer includes granular access control features to restrict access to specific tables and columns, providing an additional layer of security beyond basic authentication.

#### Access Control Modes

DBViewer supports three access control modes:

- **`:none`** (default) - All tables are accessible (current behavior)
- **`:whitelist`** - Only explicitly allowed tables are accessible (most secure)
- **`:blacklist`** - All tables except explicitly blocked ones are accessible

#### Whitelist Mode (Recommended for Production)

Whitelist mode is the most secure approach, where only explicitly allowed tables can be accessed:

### Generate Example Configuration

Use the generator to create an example PII configuration:

```bash
rails generate dbviewer:install
```

This creates `config/initializers/dbviewer_pii_example.rb` with comprehensive examples.

For detailed PII masking documentation, see [PII_MASKING.md](docs/PII_MASKING.md).

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
  gem "dbviewer"

  # Or specify a version
  gem "dbviewer", "~> 0.7.2"
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
cd sample/app
bin/rails db:prepare
bin/rails db:migrate
bin/rails db:seed
cd ../..

# Prepare test environment
cd sample/app && bin/rails db:test:prepare && cd ../..
```

### Development Commands

```bash
# Start the development server
cd sample/app && bin/rails server

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

1. Start the dummy Rails application: `cd sample/app && bin/rails server`
2. Visit `http://localhost:3000/dbviewer` to test your changes
3. The dummy app includes sample data across multiple tables to test various DBViewer features

### Architecture Diagram

```mermaid
graph TB
    subgraph "DBViewer Engine"
        Engine[Engine<br/>Rails::Engine]
        Config[Configuration<br/>Settings & Defaults]
    end

    subgraph "Controllers Layer"
        HomeController[HomeController<br/>Dashboard & Overview]
        TablesController[TablesController<br/>Table Operations]
        LogsController[LogsController<br/>Query Logs]
        ERDController[ERDController<br/>Entity Relationships]
        APIController[API Controllers<br/>JSON Endpoints]
        ConnectionsController[ConnectionsController<br/>Database Connections]
    end

    subgraph "Controller Concerns"
        DatabaseOperations[DatabaseOperations<br/>Shared Database Logic]
    end

    subgraph "Database Namespace"
        Manager[Manager<br/>Database Operations]
        MetadataManager[MetadataManager<br/>Schema Information]
        DynamicModelFactory[DynamicModelFactory<br/>ActiveRecord Models]
    end

    subgraph "Cache Namespace"
        CacheBase[Base<br/>Cache Interface]
        InMemoryCache[InMemory<br/>In-Memory Cache Storage]
    end

    subgraph "Query Namespace"
        QueryExecutor[Executor<br/>SQL Execution]
        QueryLogger[Logger<br/>Query Logging]
        QueryAnalyzer[Analyzer<br/>Performance Analysis]
        QueryParser[Parser<br/>SQL Parsing]
        NotificationSubscriber[NotificationSubscriber<br/>Query Notifications]
    end

    subgraph "Datatable Namespace"
        QueryOperations[QueryOperations<br/>Table Queries & Filtering]
        QueryParams[QueryParams<br/>Parameter Handling]
        ColumnFiltering[apply_single_column_filter<br/>Individual Filter Logic]
    end

    subgraph "Storage Namespace"
        StorageBase[Base<br/>Storage Interface]
        InMemoryStorage[InMemoryStorage<br/>Memory Storage]
        FileStorage[FileStorage<br/>File Storage]
    end

    subgraph "Validation Namespace"
        ValidatorSql[Validator::Sql<br/>Query Validation]
    end

    %% Configuration Dependencies (Decoupled)
    Config -.->|"Dependency Injection"| Manager
    Manager -->|"cache_expiry"| InMemoryCache
    Manager -->|"config object"| QueryExecutor

    %% Engine Initialization
    Engine --> HomeController
    Engine --> TablesController
    Engine --> LogsController
    Engine --> ERDController
    Engine --> ConnectionsController
    Engine -.->|"setup()"| QueryLogger
    Engine -.->|"subscribe"| NotificationSubscriber

    %% Controller Dependencies
    TablesController --> DatabaseOperations
    HomeController --> DatabaseOperations
    ConnectionsController --> DatabaseOperations
    APIController --> DatabaseOperations
    LogsController -.->|"Get List"| QueryLogger

    DatabaseOperations --> Manager
    DatabaseOperations --> QueryOperations

    %% Manager Dependencies
    Manager --> InMemoryCache
    Manager --> MetadataManager
    Manager --> DynamicModelFactory
    Manager --> QueryOperations

    %% Cache Dependencies
    InMemoryCache --> DynamicModelFactory
    InMemoryCache --> MetadataManager

    %% QueryOperations Dependencies (Refactored)
    QueryOperations --> DynamicModelFactory
    QueryOperations --> MetadataManager
    QueryOperations --> QueryAnalyzer
    QueryOperations --> ColumnFiltering

    %% Storage Dependencies
    QueryLogger --> StorageBase
    StorageBase --> InMemoryStorage
    StorageBase --> FileStorage

    %% Configuration Flow
    Config -.->|"logging settings"| QueryLogger
    Config -.->|"database connections"| Manager

    %% Validation
    ValidatorSql --> QueryExecutor

    %% Styling
    class InMemoryCache,QueryLogger decoupled
    class HomeController,TablesController,LogsController,ERDController,APIController,ConnectionsController controller
    class DatabaseOperations concern
    class Manager,MetadataManager,DynamicModelFactory database
    class CacheBase,InMemoryCache cache
    class QueryExecutor,QueryAnalyzer,QueryParser,NotificationSubscriber query
    class StorageBase,InMemoryStorage,FileStorage storage
    class ColumnFiltering filtering
    class ValidatorSql validation
```

## 🤌🏻 Contributing

Bug reports and pull requests are welcome.

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
