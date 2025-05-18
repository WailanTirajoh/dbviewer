
Dbviewer.configure do |config|
  config.per_page_options = [ 10, 20, 50, 100, 250 ] # Default pagination options
  config.default_per_page = 20                       # Default records per page
  config.max_query_length = 10000                    # Maximum SQL query length
  config.cache_expiry = 300                          # Cache expiration in seconds
  config.max_records = 10000                         # Maximum records to return in any query
  config.enable_data_export = false                  # Whether to allow data exporting
  config.query_timeout = 30                          # SQL query timeout in seconds
  config.query_logging_mode = :file                  # Storage mode for SQL queries (:memory or :file)
  config.query_log_path = "log/dbviewer.log"         # Path for query log file when in :file mode
  config.max_memory_queries = 1000                   # Maximum number of queries to store in memory
end
