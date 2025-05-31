require "dbviewer/version"
require "dbviewer/configuration"
require "dbviewer/engine"
require "dbviewer/sql_validator"

require "dbviewer/storage/base"
require "dbviewer/storage/in_memory_storage"
require "dbviewer/storage/file_storage"

require "dbviewer/query/executor"
require "dbviewer/query/analyzer"
require "dbviewer/query/collection"
require "dbviewer/query/logger"
require "dbviewer/query/parser"

require "dbviewer/database/cache_manager"
require "dbviewer/database/dynamic_model_factory"
require "dbviewer/database/manager"
require "dbviewer/database/metadata_manager"

require "dbviewer/datatable/query_operations"
require "dbviewer/datatable/query_params"

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
      # Configure the query logger with current configuration settings
      Dbviewer::Query::Logger.configure(
        enable_query_logging: configuration.enable_query_logging,
        query_logging_mode: configuration.query_logging_mode
      )

      # Check all configured connections
      connection_errors = []
      configuration.database_connections.each do |key, config|
        begin
          connection_class = nil

          if config[:connection]
            connection_class = config[:connection]
          elsif config[:connection_class].is_a?(String)
            # Try to load the class if it's defined as a string
            begin
              connection_class = config[:connection_class].constantize
            rescue NameError => e
              Rails.logger.warn "DBViewer could not load connection class #{config[:connection_class]}: #{e.message}"
              next
            end
          end

          if connection_class
            connection = connection_class.connection
            adapter_name = connection.adapter_name
            Rails.logger.info "DBViewer successfully connected to #{config[:name] || key.to_s} database (#{adapter_name})"

            # Store the resolved connection class back in the config
            config[:connection] = connection_class
          else
            raise "No valid connection configuration found for #{key}"
          end
        rescue => e
          connection_errors << { key: key, error: e.message }
          Rails.logger.error "DBViewer could not connect to #{config[:name] || key.to_s} database: #{e.message}"
        end
      end

      if connection_errors.length == configuration.database_connections.length
        raise "DBViewer could not connect to any configured database"
      end
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
