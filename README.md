# DBViewer

DBViewer is a powerful Rails engine that provides a comprehensive interface to view and explore database tables, records, and schema.
It's designed for development, debugging, and database analysis, offering a clean and intuitive way to interact with your application's database.

## Features

- **Table Overview**: View a list of all tables with record count, column count, and quick access links
- **Detailed Schema Information**:
  - View columns with their types, nullability, defaults, and primary key indicators
  - Examine table indexes and their uniqueness constraints
  - Explore foreign key relationships between tables
- **Data Browsing**:
  - Browse table records with customizable pagination (10, 20, 50, or 100 records per page)
  - Sort data by any column in ascending or descending order
  - Navigate through large datasets with an intuitive pagination interface
- **SQL Queries**:
  - Run custom SELECT queries against your database in a secure, read-only environment
  - View table structure reference while writing queries
  - Protection against potentially harmful SQL operations
  - Query execution statistics and timing
- **UI Features**:
  - Responsive, Bootstrap-based interface that works on desktop and mobile
  - Clean tabbed interface for exploring different aspects of table structure
  - Proper formatting for various data types (dates, JSON, arrays, etc.)
  - Enhanced data presentation with appropriate styling

## Installation

Add this line to your application's Gemfile:

```ruby
gem "dbviewer", group: :development
```

And then execute:

```bash
$ bundle
```

## Usage

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

### Available Pages

- **Table Index** (`/dbviewer`): Shows all tables in your database with their record count and column count
- **Table Details** (`/dbviewer/databases/:table_name`): Shows table structure and records with pagination
- **SQL Query** (`/dbviewer/databases/:table_name/query`): Allows running custom SQL queries

## Extending DBViewer

### Adding Custom Styles

You can add custom styles by creating an initializer:

```ruby
# config/initializers/dbviewer.rb
Rails.application.config.to_prepare do
  Dbviewer::ApplicationController.class_eval do
    helper_method :custom_dbviewer_stylesheets

    def custom_dbviewer_stylesheets
      # Return an array of stylesheet paths to include
      %w[your_custom_stylesheet]
    end
  end
end
```

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

## Configuration Options

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
end
```

The configuration is accessed through `Dbviewer.configuration` throughout the codebase. You can also access it via `Dbviewer.config` which is an alias for backward compatibility.

## Security Features

DBViewer includes several security features to protect your database:

- **Read-only Mode**: Only SELECT queries are allowed; all data modification operations are blocked
- **SQL Validation**: Prevents potentially harmful operations with comprehensive validation
- **Query Limits**: Automatic LIMIT clause added to prevent excessive data retrieval
- **Pattern Detection**: Detection of SQL injection patterns and suspicious constructs
- **Error Handling**: Informative error messages without exposing sensitive information

## Production Access (Not Recommended)

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

## Security Note

⚠️ **Warning**: This engine is designed for development purposes. It's not recommended to use it in production as it provides direct access to your database contents. If you must use it in production, ensure it's protected behind authentication and use the production access key mechanism with a strong random key.

## Contributing

Bug reports and pull requests are welcome.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
```
