Dbviewer.configure do |config|
  config.per_page_options = [ 10, 20, 50, 100, 250 ] # Default pagination options
  config.default_per_page = 50                       # Default records per page
  config.max_query_length = 10000                    # Maximum SQL query length
  config.cache_expiry = 300                          # Cache expiration in seconds
  config.max_records = 10000                         # Maximum records to return in any query
  config.enable_data_export = false                  # Whether to allow data exporting
  config.query_timeout = 30                          # SQL query timeout in seconds

  # Query logging options
  config.enable_query_logging = true                 # Enable or disable query logging completely (default: true)
  config.query_logging_mode = :file                  # Storage mode for SQL queries (:memory or :file)
  config.query_log_path = "log/dbviewer.log"         # Path for query log file when in :file mode
  config.max_memory_queries = 1000                   # Maximum number of queries to store in memory

  # PII Masking Configuration
  config.enable_pii_masking = true                   # Enable PII masking globally (default: true)

  # Multiple database connections
  config.database_connections = {
    primary: {
      connection_class: "ActiveRecord::Base",
      name: "Primary DB (E-commerce)"
    },
    secondary: {
      connection_class: "SecondaryDatabase",
      name: "Blog Database"
    }
  }
  config.current_connection = :primary

  # DBViewer disabled state (for testing purposes, normally false)
  config.disabled = false

  # Authentication options (Basic Auth)
  # config.admin_credentials = {
  #   username: "admin",
  #   password: "your_secure_password"
  # }

  # Table and Column Access Control (Security Feature)
  # Access control mode: :whitelist (most secure), :blacklist, or :none (default)
  config.access_control_mode = :none

  # Whitelist mode: Only these tables will be accessible
  config.allowed_tables = [
    'users',
    'orders',
    'products',
    'categories'
  ]

  # Blacklist mode: All tables except these will be accessible
  # config.blocked_tables = [
  #   'users'
  # ]

  # Hide sensitive columns from specific tables
  # config.blocked_columns = {
  #   'users' => ['password_digest', 'api_key', 'secret_token'],
  #   'orders' => ['internal_notes', 'admin_comments']
  # }
end
