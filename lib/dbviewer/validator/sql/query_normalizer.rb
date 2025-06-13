# frozen_string_literal: true

module Dbviewer
  module Validator
    class Sql
      # Module for query normalization operations
      # This module handles the cleaning and standardization of SQL queries
      # to prepare them for validation and threat detection.
      module QueryNormalizer
        extend self

        # Normalize SQL by removing comments and extra whitespace
        # This prepares the query for consistent validation by:
        # - Removing SQL comments (both -- and /* */ styles)
        # - Normalizing whitespace to single spaces
        # - Trimming leading/trailing whitespace
        #
        # @param sql [String] The SQL query to normalize
        # @return [String] The normalized SQL query
        def normalize(sql)
          return "" if sql.nil?

          begin
            normalized = remove_comments(sql)
            normalized = normalize_whitespace(normalized)
            normalized.strip
          rescue => e
            # Log error if Rails logger is available, otherwise use basic error handling
            if defined?(Rails) && Rails.respond_to?(:logger)
              Rails.logger.error("[DBViewer] SQL normalization error: #{e.message}")
            else
              # Fallback to stderr if Rails is not available
              $stderr.puts "[DBViewer] SQL normalization error: #{e.message}"
            end
            ""
          end
        end

        private

        # Remove SQL comments from the query
        # Handles both single-line (--) and multi-line (/* */) comment styles
        #
        # @param sql [String] The SQL query
        # @return [String] SQL with comments removed
        def remove_comments(sql)
          sql.gsub(/--.*$/, "")                # Remove -- style comments
             .gsub(/\/\*.*?\*\//m, "")        # Remove /* */ style comments
        end

        # Normalize whitespace in the SQL query
        # Converts all whitespace sequences to single spaces for consistent parsing
        #
        # @param sql [String] The SQL query
        # @return [String] SQL with normalized whitespace
        def normalize_whitespace(sql)
          sql.gsub(/\s+/, " ")                # Normalize whitespace
             .gsub(/\s{2,}/, " ")             # Replace multiple spaces with single space
        end
      end
    end
  end
end
