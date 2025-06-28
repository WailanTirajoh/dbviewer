require "dbviewer/version"
require "dbviewer/configuration"
require "dbviewer/engine"
require "dbviewer/validator/sql"
require "dbviewer/security/sql_parser"
require "dbviewer/security/access_control"

require "dbviewer/storage/base"
require "dbviewer/storage/in_memory_storage"
require "dbviewer/storage/file_storage"

require "dbviewer/cache/base"
require "dbviewer/cache/in_memory"

require "dbviewer/query/executor"
require "dbviewer/query/analyzer"
require "dbviewer/query/logger"
require "dbviewer/query/notification_subscriber"
require "dbviewer/query/parser"

require "dbviewer/database/dynamic_model_factory"
require "dbviewer/database/manager"
require "dbviewer/database/metadata_manager"

require "dbviewer/datatable/query_operations"
require "dbviewer/datatable/query_params"

require "dbviewer/data_privacy/pii_masker"

require "propshaft"

module Dbviewer
  # Main module for the database viewer

  # Helper class for configuring PII masking rules
  class PiiConfigurator
    def initialize(configuration)
      @configuration = configuration
    end

    # Define a PII masking rule
    # @param column_spec [String] Table and column in format "table.column"
    # @param with [Symbol, Proc] Masking rule - either built-in symbol or custom proc
    def mask(column_spec, with:)
      @configuration.pii_rules[column_spec] = with
    end

    # Define a custom masking function
    # @param name [Symbol] Name of the custom mask
    # @param block [Proc] The masking function
    def custom_mask(name, block)
      @configuration.custom_pii_masks[name] = block
    end

    # Enable or disable PII masking globally
    # @param enabled [Boolean] Whether to enable PII masking
    def enabled=(enabled)
      @configuration.enable_pii_masking = enabled
    end
  end

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

    # Configure PII masking rules using a block
    #
    # @example
    #   Dbviewer.configure_pii do |pii|
    #     pii.mask 'users.email', with: :email
    #     pii.mask 'users.phone', with: :phone
    #     pii.mask 'users.ssn', with: :ssn
    #     pii.mask 'customers.credit_card', with: :credit_card
    #     pii.mask 'profiles.secret', with: :full_redact
    #     pii.mask 'accounts.api_key', with: ->(value) { value ? 'api_***' : value }
    #     pii.custom_mask :my_custom, ->(value) { "CUSTOM: #{value[0]}***" }
    #   end
    def configure_pii
      yield(PiiConfigurator.new(configuration)) if block_given?
    end

    # This class method will be called by the engine when it's appropriate
    def setup
      Dbviewer::Query::Logger.configure(
        enable_query_logging: configuration.enable_query_logging,
        query_logging_mode: configuration.query_logging_mode
      )

      Rails.logger.info "DBViewer: Initialized successfully"
    end
  end
end
