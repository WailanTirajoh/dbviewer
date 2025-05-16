# DBViewer

DBViewer is a Rails engine that provides a simple interface to view database tables and their records.
It's useful for development and debugging purposes, allowing you to quickly explore your database structure.

## Features

- View a list of all tables in your database with record count and column count
- View detailed table structure (columns with their types, nullability, and defaults)
- Browse table records with pagination and column sorting
- Run custom SQL queries against your database
- Responsive, Bootstrap-based UI with clean design
- Proper formatting for various data types (dates, JSON, etc.)

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

## Production Access (Not Recommended)

By default, DBViewer only runs in development or test environments for security reasons. If you need to access it in production (not recommended):

1. Set an environment variable with a secure random key:

   ```
   DBVIEWER_PRODUCTION_ACCESS_KEY=your_secure_random_key
   ```

2. Access the tool with the override parameter:
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
