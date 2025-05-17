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
    def configuration
      @configuration ||= Configuration.new
    end

    # Alias for backward compatibility
    def config
      configuration
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
      Dbviewer::DatabaseManager.singleton_class.class_eval do
        define_method(:configuration) { Dbviewer.configuration }
        define_method(:default_per_page) { Dbviewer.configuration.default_per_page }
        define_method(:max_records) { Dbviewer.configuration.max_records }
        define_method(:cache_expiry) { Dbviewer.configuration.cache_expiry }
      end

      # Define class methods to access configuration
      Dbviewer::SqlValidator.singleton_class.class_eval do
        define_method(:configuration) { Dbviewer.configuration }
        define_method(:max_query_length) { Dbviewer.configuration.max_query_length }
      end

      # Log initialization
      Rails.logger.info("[DBViewer] Initialized with configuration: #{configuration.inspect}")
    end
  end
end
