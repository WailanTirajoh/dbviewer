require "dbviewer/version"
require "dbviewer/configuration"
require "dbviewer/engine"
require "dbviewer/error_handler"
require "dbviewer/cache_manager"
require "dbviewer/table_metadata_manager"
require "dbviewer/dynamic_model_factory"
require "dbviewer/query_executor"
require "dbviewer/table_query_operations"
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

    # Configure the engine with a block
    #
    # @example
    #   Dbviewer.configure do |config|
    #     config.per_page_options = [10, 25, 50]
    #     config.default_per_page = 25
    #   end
    def configure
      yield(configuration) if block_given?
    end

    # Reset configuration to defaults
    def reset_configuration
      @configuration = Configuration.new
    end

    # This class method will be called by the engine when it's appropriate
    def setup
      ActiveRecord::Base.connection
      Rails.logger.info "DBViewer successfully connected to database"
    rescue => e
      Rails.logger.error "DBViewer could not connect to database: #{e.message}"
    end

    # Initialize engine with default values or user-provided configuration
    def init
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
