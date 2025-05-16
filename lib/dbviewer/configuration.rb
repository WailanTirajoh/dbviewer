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

    # Admin access credentials (username, password)
    attr_accessor :admin_credentials

    def initialize
      @per_page_options = [10, 20, 50, 100]
      @default_per_page = 20
      @max_records = 10000
      @max_query_length = 10000
      @cache_expiry = 300
      @enable_data_export = false
      @query_timeout = 30
      @admin_credentials = nil
    end
  end

  # Class accessor for configuration
  class << self
    attr_accessor :configuration
  end

  # Configure the engine with a block
  #
  # @example
  #   Dbviewer.configure do |config|
  #     config.per_page_options = [10, 25, 50]
  #     config.default_per_page = 25
  #   end
  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  # Reset configuration to defaults
  def self.reset_configuration
    self.configuration = Configuration.new
  end

  # Get the current configuration
  # Creates a default configuration if none exists
  def self.configuration
    @configuration ||= Configuration.new
  end
end
