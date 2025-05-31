# Multiple Database Connections

DBViewer supports working with multiple database connections in your application. This is especially useful if your application connects to multiple databases or uses different database connections for different models.

## Configuration

Configure multiple database connections in your initializer:

```ruby
# config/initializers/dbviewer.rb
Dbviewer.configure do |config|
  config.database_connections = {
    primary: {
      connection_class: "ActiveRecord::Base",
      name: "Primary Database"
    },
    secondary: {
      connection_class: "SecondaryDatabase",
      name: "Secondary Database"
    }
  }

  # Set the default active connection
  config.current_connection = :primary
end
```

Each connection requires:

- A unique key (symbol)
- A `connection_class` (string) that defines the ActiveRecord class handling the connection
- A human-readable `name` that will be displayed in the UI

## Adding Connections Dynamically

DBViewer also supports adding connections at runtime through the user interface:

1. Navigate to the Connections page
2. Click "Add Connection" button
3. Enter the connection details:
   - Connection Name: A human-readable name for the connection
   - Connection Key: A unique identifier for the connection
   - Connection Class: The fully qualified ActiveRecord class name that handles the connection

## Connection Management

You can:

- Switch between connections using the dropdown in the navigation bar
- View and manage all connections from the Connections page
- Test connections to verify they're working
- Remove connections that are no longer needed

## Example Setup

For an application with a primary database and a blog database:

```ruby
# app/models/secondary_database.rb
class SecondaryDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :secondary_database
end

# app/models/blog_post.rb (connects to secondary database)
class BlogPost < SecondaryDatabase
  # blog post model definition
end

# config/database.yml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: db/development.sqlite3

secondary_database:
  <<: *default
  database: db/blog.sqlite3

# config/initializers/dbviewer.rb
Dbviewer.configure do |config|
  config.database_connections = {
    primary: {
      connection_class: "ActiveRecord::Base",
      name: "Main Database"
    },
    blog: {
      connection_class: "SecondaryDatabase",
      name: "Blog Database"
    }
  }
end
```

## Notes

- Each connection needs a valid ActiveRecord class that establishes the connection
- Make sure the connection class is properly loaded before DBViewer tries to use it
- Any errors in connection setup will be logged and displayed in the UI
