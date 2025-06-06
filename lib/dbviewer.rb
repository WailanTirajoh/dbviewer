require "dbviewer/version"
require "dbviewer/configuration"
require "dbviewer/engine"
require "dbviewer/validator"
require "dbviewer/validator/sql"

require "dbviewer/storage/base"
require "dbviewer/storage/in_memory_storage"
require "dbviewer/storage/file_storage"

require "dbviewer/query/executor"
require "dbviewer/query/analyzer"
require "dbviewer/query/collection"
require "dbviewer/query/logger"
require "dbviewer/query/notification_subscriber"
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
      configure_query_logger
      validate_database_connections
    end

    private

    # Configure the query logger with current configuration settings
    def configure_query_logger
      Dbviewer::Query::Logger.configure(
        enable_query_logging: configuration.enable_query_logging,
        query_logging_mode: configuration.query_logging_mode
      )
    end

    # Validate all configured database connections
    def validate_database_connections
      connection_errors = configuration.database_connections.filter_map do |key, config|
        validate_single_connection(key, config)
      end

      raise_if_all_connections_failed(connection_errors)
    end

    # Validate a single database connection
    # @param key [Symbol] The connection key
    # @param config [Hash] The connection configuration
    # @return [Hash, nil] Error hash if validation failed, nil if successful
    def validate_single_connection(key, config)
      connection_class = resolve_connection_class(config)
      return { key: key, error: "No valid connection configuration found for #{key}" } unless connection_class

      test_connection(connection_class, config, key)
      store_resolved_connection(config, connection_class)
      nil
    rescue => e
      Rails.logger.error "DBViewer could not connect to #{config[:name] || key.to_s} database: #{e.message}"
      { key: key, error: e.message }
    end

    # Resolve the connection class from configuration
    # @param config [Hash] The connection configuration
    # @return [Class, nil] The resolved connection class or nil
    def resolve_connection_class(config)
      return config[:connection] if config[:connection]
      return nil unless config[:connection_class].is_a?(String)

      begin
        config[:connection_class].constantize
      rescue NameError => e
        Rails.logger.warn "DBViewer could not load connection class #{config[:connection_class]}: #{e.message}"
        nil
      end
    end

    # Test the database connection
    # @param connection_class [Class] The connection class
    # @param config [Hash] The connection configuration
    # @param key [Symbol] The connection key
    def test_connection(connection_class, config, key)
      connection = connection_class.connection
      adapter_name = connection.adapter_name
      Rails.logger.info "DBViewer successfully connected to #{config[:name] || key.to_s} database (#{adapter_name})"
    end

    # Store the resolved connection class back in the config
    # @param config [Hash] The connection configuration
    # @param connection_class [Class] The resolved connection class
    def store_resolved_connection(config, connection_class)
      config[:connection] = connection_class
    end

    # Raise an error if all database connections failed
    # @param connection_errors [Array] Array of connection error hashes
    def raise_if_all_connections_failed(connection_errors)
      if connection_errors.length == configuration.database_connections.length
        raise "DBViewer could not connect to any configured database"
      end
    end
  end
end
