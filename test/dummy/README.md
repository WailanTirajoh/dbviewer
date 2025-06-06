# DBViewer Test Application

This is a dummy application used for testing and developing the DBViewer Rails engine.

## Database Setup

This application uses PostgreSQL for the primary database and SQLite3 for the secondary database.

### Setup Instructions

1. Copy the environment variables example file:

   ```
   cp .env.example .env
   ```

2. Edit the `.env` file with your PostgreSQL credentials:

   ```
   PG_USERNAME=your_postgres_username
   PG_PASSWORD=your_postgres_password
   PG_HOST=localhost
   ```

3. Create the PostgreSQL databases:

   ```
   createdb dbviewer_development
   createdb dbviewer_test
   ```

4. Run the migrations:

   ```
   bin/rails db:migrate
   ```

5. You can start the application with:
   ```
   bin/rails server
   ```

## Using dotenv

This application uses the dotenv-rails gem to load environment variables from `.env` files. The gem is configured to load `.env` files in development and test environments.

- `.env` - Contains default values for all environments
- `.env.development` - Environment-specific variables for development
- `.env.test` - Environment-specific variables for test

The `.env` file should not be committed to source control as it contains sensitive information.
