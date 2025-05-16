require "dbviewer/version"
require "dbviewer/configuration"
require "dbviewer/engine"
require "dbviewer/initializer"
require "dbviewer/database_manager"
require "dbviewer/sql_validator"

module Dbviewer
  # Main module for the database viewer

  class << self
    # Module accessor for configuration
    attr_writer :configuration

    # Get configuration settings
    def config
      @configuration ||= Configuration.new
    end

    # Alias to make the API more intuitive
    def configuration
      config
    end

    # Configure the engine with a block
    #
    # @example
    #   Dbviewer.configure do |config|
    #     config.per_page_options = [10, 25, 50]
    #     config.default_per_page = 25
    #   end
    def configure
      yield(config) if block_given?
    end

    # Reset configuration to defaults
    def reset_configuration
      @configuration = Configuration.new
    end

    # This class method will be called by the engine when it's appropriate
    def setup
      Dbviewer::Initializer.setup
    end

    # Initialize engine with default values or user-provided configuration
    def init
      # Apply configuration values to components
      apply_configuration

      # Log initialization
      Rails.logger.info("[DBViewer] Initialized with configuration: #{config.inspect}")
    end

    private

    # Apply configuration values to the appropriate components
    def apply_configuration
      # Get the configuration object
      config_obj = config

      # Update DatabaseManager constants
      if defined?(Dbviewer::DatabaseManager)
        Dbviewer::DatabaseManager.const_set(:DEFAULT_PER_PAGE, config_obj.default_per_page)
        Dbviewer::DatabaseManager.const_set(:MAX_RECORDS, config_obj.max_records)
        Dbviewer::DatabaseManager.const_set(:CACHE_EXPIRY, config_obj.cache_expiry)
      end

      # Update SqlValidator constants
      if defined?(Dbviewer::SqlValidator)
        Dbviewer::SqlValidator.const_set(:MAX_QUERY_LENGTH, config_obj.max_query_length)
      end
    end
  end
end
