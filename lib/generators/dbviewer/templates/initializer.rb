Dbviewer.configure do |config|
  config.per_page_options = [ 10, 20, 50, 100, 250 ]
  config.default_per_page = 20
  config.max_query_length = 10000
  config.cache_expiry = 300
  config.max_records = 10000
  config.enable_data_export = false
  config.query_timeout = 30

  # Query logging options
  config.enable_query_logging = false
  config.query_logging_mode = :memory
  config.query_log_path = "log/dbviewer.log"
  config.max_memory_queries = 1000

  # Authentication options
  # config.admin_credentials = { username: "admin", password: "your_secure_password" } # Basic HTTP auth credentials

  # Default table ordering options
  config.default_order_column = "updated_at"  # Primary column to order by
end
