module Dbviewer
  # Configuration class for DBViewer engine settings
  class Configuration
    # Default pagination options
    attr_accessor :per_page_options

    # Default number of records per page
    attr_accessor :default_per_page

    # Maximum number of records to return in any query
    attr_accessor :max_records

    # Maximum SQL query length allowed
    attr_accessor :max_query_length

    # Cache expiration time in seconds
    attr_accessor :cache_expiry

    # Allow downloading of data in various formats
    attr_accessor :enable_data_export

    # Timeout for SQL queries in seconds
    attr_accessor :query_timeout

    # Query logging storage mode (:memory or :file)
    attr_accessor :query_logging_mode

    # Path for query log file when in :file mode
    attr_accessor :query_log_path

    # Maximum number of queries to keep in memory
    attr_accessor :max_memory_queries

    # Enable or disable query logging completely
    attr_accessor :enable_query_logging

    # Admin access credentials hash with :username and :password keys
    # @example { username: 'admin', password: 'secret' }
    attr_accessor :admin_credentials

    # Default column to order table details by (e.g., 'updated_at')
    attr_accessor :default_order_column

    # Multiple database connections configuration
    # @example {
    #   primary: { connection_class: "ActiveRecord::Base", name: "Primary DB" },
    #   secondary: { connection_class: "SomeClass", name: "Secondary DB" }
    # }
    attr_accessor :database_connections

    # The key of the current active connection
    attr_accessor :current_connection

    # Whether to validate database connections during application startup
    # Set to false in production/CI environments to avoid startup failures
    attr_accessor :validate_connections_on_startup

    def initialize
      @per_page_options = [ 10, 20, 50, 100 ]
      @default_per_page = 20
      @max_records = 10000
      @max_query_length = 10000
      @cache_expiry = 300
      @enable_data_export = false
      @query_timeout = 30
      @query_logging_mode = :memory
      @query_log_path = "log/dbviewer.log"
      @max_memory_queries = 1000
      @enable_query_logging = true
      @admin_credentials = nil
      @default_order_column = "updated_at"
      @validate_connections_on_startup = false  # Default to false for safer deployments
      @database_connections = {
        default: {
          connection_class: "ActiveRecord::Base",
          name: "Default Database"
        }
      }
      @current_connection = :default
    end
  end
end
