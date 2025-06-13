# frozen_string_literal: true

module Dbviewer
  module Validator
    class Sql
      # Validation result object to encapsulate validation state and errors
      # This provides a structured way to return validation results with
      # clear success/failure states and associated error messages.
      ValidationResult = Struct.new(:valid?, :error_message, :normalized_sql, keyword_init: true) do
        # Check if the validation was successful
        # @return [Boolean] true if validation passed
        def success?
          valid?
        end

        # Check if the validation failed
        # @return [Boolean] true if validation failed
        def failure?
          !valid?
        end

        # Create a successful validation result
        # @param normalized_sql [String] The normalized SQL query
        # @return [ValidationResult] Success result with normalized SQL
        def self.success(normalized_sql)
          new(valid?: true, normalized_sql: normalized_sql)
        end

        # Create a failed validation result
        # @param error_message [String] Description of the validation failure
        # @return [ValidationResult] Failure result with error message
        def self.failure(error_message)
          new(valid?: false, error_message: error_message)
        end
      end
    end
  end
end
