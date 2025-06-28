# frozen_string_literal: true

require_relative "sql/validation_result"
require_relative "sql/validation_config"
require_relative "sql/query_normalizer"
require_relative "sql/threat_detector"

module Dbviewer
  module Validator
    # Sql class handles SQL query validation and normalization
    # to ensure queries are safe (read-only) and properly formatted.
    # This helps prevent potentially destructive SQL operations.
    class Sql
      # Core validation methods
      class << self
        # Determines if a query is safe (read-only)
        # @param sql [String] The SQL query to validate
        # @return [Boolean] true if the query is safe, false otherwise
        def safe_query?(sql)
          result = validate_query(sql, allow_pragma: false)
          result.success?
        end

        # Validates a query and raises an exception if it's unsafe
        # @param sql [String] The SQL query to validate
        # @raise [SecurityError] if the query is unsafe
        # @return [String] The normalized SQL query if it's safe
        def validate!(sql)
          result = validate_query(sql, allow_pragma: true)

          if result.failure?
            raise SecurityError, result.error_message
          end

          result.normalized_sql
        end

        private

        # Main validation logic that returns a structured result
        # @param sql [String] The SQL query to validate
        # @param allow_pragma [Boolean] Whether to allow PRAGMA statements
        # @return [ValidationResult] Validation result with status and details
        def validate_query(sql, allow_pragma: true)
          # Step 1: Basic input validation
          basic_validation_result = perform_basic_validation(sql)
          return basic_validation_result if basic_validation_result

          # Step 2: Security threat detection (before normalization)
          threat_validation_result = perform_threat_validation(sql)
          return threat_validation_result if threat_validation_result

          # Step 3: Normalize the query
          normalized_sql = QueryNormalizer.normalize(sql)

          # Step 4: Handle special cases (PRAGMA) - only if allowed
          if allow_pragma
            pragma_result = handle_pragma_statements(normalized_sql)
            return pragma_result if pragma_result
          end

          # Step 5: Validate query structure and keywords
          structure_validation_result = perform_structure_validation(normalized_sql)
          return structure_validation_result if structure_validation_result

          # Step 6: Check for multiple statements
          multiple_statements_result = validate_single_statement(normalized_sql)
          return multiple_statements_result if multiple_statements_result

          # Success case
          ValidationResult.new(
            valid?: true,
            normalized_sql: normalized_sql
          )
        end

        # Perform basic input validation (null, empty, length)
        def perform_basic_validation(sql)
          if sql.nil? || sql.strip.empty?
            return ValidationResult.new(
              valid?: false,
              error_message: "Empty query is not allowed"
            )
          end

          max_length = get_max_query_length
          if sql.length > max_length
            return ValidationResult.new(
              valid?: false,
              error_message: "Query exceeds maximum allowed length (#{max_length} chars)"
            )
          end

          nil # No validation errors
        end

        # Perform security threat detection
        def perform_threat_validation(sql)
          if ThreatDetector.has_suspicious_patterns?(sql)
            log_security_threat("suspicious_patterns", sql)
            return ValidationResult.new(
              valid?: false,
              error_message: "Query contains suspicious patterns that may indicate SQL injection"
            )
          end

          if ThreatDetector.has_injection_patterns?(sql)
            log_security_threat("injection_patterns", sql)
            return ValidationResult.new(
              valid?: false,
              error_message: "Query contains patterns commonly associated with SQL injection attempts"
            )
          end

          nil # No security threats detected
        end

        # Handle special PRAGMA statements for SQLite
        def handle_pragma_statements(normalized_sql)
          if pragma_statement?(normalized_sql)
            return ValidationResult.new(
              valid?: true,
              normalized_sql: normalized_sql
            )
          end

          nil # Not a PRAGMA statement
        end

        # Validate query structure and forbidden keywords
        def perform_structure_validation(normalized_sql)
          unless valid_query_start?(normalized_sql)
            return ValidationResult.new(
              valid?: false,
              error_message: "Query must begin with SELECT or WITH for security reasons"
            )
          end

          forbidden_keyword = detect_forbidden_keywords(normalized_sql)
          if forbidden_keyword
            return ValidationResult.new(
              valid?: false,
              error_message: "Forbidden keyword '#{forbidden_keyword}' detected in query"
            )
          end

          nil # Structure validation passed
        end

        # Validate that query contains only a single statement
        def validate_single_statement(normalized_sql)
          statements = normalized_sql.split(";").reject { |s| s.nil? || s.strip.empty? }
          if statements.size > 1
            return ValidationResult.new(
              valid?: false,
              error_message: "Multiple SQL statements are not allowed"
            )
          end

          nil # Single statement validation passed
        end

        # Helper methods
        def get_max_query_length
          # Try to get from configuration if available, otherwise use default
          if defined?(Dbviewer) && Dbviewer.respond_to?(:configuration) && Dbviewer.configuration.respond_to?(:max_query_length)
            Dbviewer.configuration.max_query_length || ValidationConfig::DEFAULT_MAX_QUERY_LENGTH
          else
            ValidationConfig::DEFAULT_MAX_QUERY_LENGTH
          end
        end

        def pragma_statement?(normalized_sql)
          normalized_sql =~ /\A\s*PRAGMA\s+[a-z0-9_]+(\([^)]*\))?\s*\z/i
        end

        def valid_query_start?(normalized_sql)
          normalized_sql =~ /\A\s*(SELECT|WITH)\s+/i
        end

        def detect_forbidden_keywords(normalized_sql)
          ValidationConfig::FORBIDDEN_KEYWORDS.find do |keyword|
            normalized_sql =~ /\b#{keyword}\b/i
          end
        end

        def detect_subqueries(normalized_sql)
          # Check if there are unbalanced parentheses that likely contain subqueries
          normalized_sql.count("(") > normalized_sql.count(")")
        end

        # Method missing handler for backward compatibility with legacy method calls
        def method_missing(method_name, *args, **kwargs, &block)
          case method_name
          when :has_suspicious_patterns?
            ThreatDetector.has_suspicious_patterns?(*args)
          when :has_injection_patterns?
            ThreatDetector.has_injection_patterns?(*args)
          when :normalize
            QueryNormalizer.normalize(*args)
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_private = false)
          [ :has_suspicious_patterns?, :has_injection_patterns?, :normalize ].include?(method_name) || super
        end

        # Log security threats for monitoring and analysis
        def log_security_threat(threat_type, sql)
          if defined?(Rails) && Rails.logger
            Rails.logger.warn("[DBViewer][Security] SQL threat detected - #{threat_type}: #{sql.truncate(200)}")
          end
          
          # Also log to query logger if available
          if defined?(::Dbviewer::Query::Logger)
            ::Dbviewer::Query::Logger.log_security_event(
              event_type: "threat_detected",
              query_type: threat_type,
              sql: sql,
              timestamp: Time.current
            )
          end
        rescue => e
          # Don't let logging errors break the validation
          puts "[DBViewer] Security logging error: #{e.message}"
        end
      end
    end
  end
end
