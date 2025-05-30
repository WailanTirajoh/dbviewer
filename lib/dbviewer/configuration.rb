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
    #   primary: { connection: ActiveRecord::Base.connection, name: "Primary DB" },
    #   secondary: { connection: SomeClass.connection, name: "Secondary DB" } 
    # }
    attr_accessor :database_connections

    # The key of the current active connection
    attr_accessor :current_connection

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
      @database_connections = { default: { connection: ActiveRecord::Base, name: "Default Database" } }
      @current_connection = :default
    end
    
    # Get the active connection class for the current connection
    # @return [Class] The ActiveRecord connection class
    def active_connection_class
      conn_config = database_connections[current_connection]
      return ActiveRecord::Base unless conn_config
      conn_config[:connection] || ActiveRecord::Base
    end
    
    # Add a new database connection at runtime
    # @param key [Symbol, String] The key for the new connection
    # @param config [Hash] The connection configuration (connection_class, name)
    # @return [Array] [success, error_message] where success is a boolean and error_message is a string or nil
    def add_connection(key, config)
      key = key.to_sym
      
      # Don't overwrite existing connections
      return [false, "Connection key already exists"] if database_connections.key?(key)
      
      # Validate required config
      unless config[:connection_class].is_a?(String)
        return [false, "Connection class must be a string"]
      end
      
      begin
        # Try to load the class if it's defined as a string
        connection_class = config[:connection_class].constantize
        
        # Test the connection to ensure it's valid
        connection = connection_class.connection
        adapter_name = connection.adapter_name
        
        # Add the connection to our configuration
        database_connections[key] = {
          connection_class: config[:connection_class],
          connection: connection_class,
          name: config[:name] || key.to_s.humanize,
          adapter_name: adapter_name
        }
        
        return [true, nil]
      rescue NameError => e
        Rails.logger.error("Failed to add connection #{key}: Connection class not found - #{e.message}")
        return [false, "Connection class not found: #{e.message}"]
      rescue => e
        Rails.logger.error("Failed to add connection #{key}: #{e.message}")
        return [false, "Connection failed: #{e.message}"]
      end
    end
    
    # Remove a database connection at runtime
    # @param key [Symbol, String] The connection key to remove
    # @return [Boolean] True if connection was removed, false otherwise
    def remove_connection(key)
      key = key.to_sym
      return false if key == :default || !database_connections.key?(key)
      
      database_connections.delete(key)
      self.current_connection = :default if current_connection == key
      
      true
    end
  end
end
