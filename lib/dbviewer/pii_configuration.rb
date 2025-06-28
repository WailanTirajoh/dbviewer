module Dbviewer
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
end
