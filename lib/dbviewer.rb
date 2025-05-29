require "dbviewer/version"
require "dbviewer/configuration"
require "dbviewer/engine"
require "dbviewer/sql_validator"

# Require namespaced modules
require "dbviewer/query/executor"
require "dbviewer/query/analyzer"
require "dbviewer/query/collection"
require "dbviewer/query/logger"
require "dbviewer/query/parser"

require "dbviewer/database/cache_manager"
require "dbviewer/database/dynamic_model_factory"
require "dbviewer/database/manager"

require "dbviewer/datatable/metadata_manager"
require "dbviewer/datatable/query_operations"
require "dbviewer/datatable/query_params"

require "dbviewer/storage/file_storage"
require "dbviewer/storage/in_memory_storage"

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
