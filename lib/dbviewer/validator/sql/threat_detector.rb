# frozen_string_literal: true

require_relative "validation_config"

module Dbviewer
  module Validator
    class Sql
      # Module for detecting various types of security threats in SQL queries
      # This module contains all the logic for identifying SQL injection attempts,
      # suspicious patterns, and other security vulnerabilities.
      module ThreatDetector
        extend self

        # Check for suspicious patterns in SQL that might indicate an attack
        # This method performs multiple checks on the raw SQL (before normalization)
        # to catch threats that might be hidden by the normalization process.
        #
        # @param sql [String] Raw SQL query (before normalization)
        # @return [Boolean] true if suspicious patterns found, false otherwise
        def has_suspicious_patterns?(sql)
          return true if has_comment_injection?(sql)
          return true if has_string_concatenation?(sql)
          return true if has_excessive_quotes?(sql)
          return true if has_hex_encoding?(sql)
          return true if has_additional_suspicious_patterns?(sql)

          false
        end

        # Check for specific SQL injection patterns
        # This method looks for known SQL injection attack patterns
        # that are commonly used by attackers.
        #
        # @param sql [String] Raw SQL query (before normalization)
        # @return [Boolean] true if injection patterns found, false otherwise
        def has_injection_patterns?(sql)
          ValidationConfig::INJECTION_PATTERNS.any? do |_name, pattern|
            sql =~ pattern
          end
        end

        # Check for forbidden keywords in the normalized SQL
        # This method scans for keywords that could modify data or schema.
        #
        # @param normalized_sql [String] Normalized SQL query
        # @return [String, nil] The forbidden keyword found, or nil if none
        def detect_forbidden_keywords(normalized_sql)
          ValidationConfig::FORBIDDEN_KEYWORDS.find do |keyword|
            normalized_sql =~ /\b#{keyword}\b/i
          end
        end

        # Check if the query starts with an allowed statement type
        # Only SELECT and WITH (for CTEs) are allowed as query starters.
        #
        # @param normalized_sql [String] Normalized SQL query
        # @return [Boolean] true if query starts with allowed statement
        def valid_query_start?(normalized_sql)
          normalized_sql =~ ValidationConfig::VALID_QUERY_START_PATTERN
        end

        # Check if the query is a SQLite PRAGMA statement
        # PRAGMA statements are allowed for database introspection.
        #
        # @param normalized_sql [String] Normalized SQL query
        # @return [Boolean] true if query is a PRAGMA statement
        def pragma_statement?(normalized_sql)
          normalized_sql =~ ValidationConfig::PRAGMA_PATTERN
        end

        # Check for multiple SQL statements separated by semicolons
        # Multiple statements could allow SQL injection attacks.
        #
        # @param normalized_sql [String] Normalized SQL query
        # @return [Boolean] true if multiple statements detected
        def has_multiple_statements?(normalized_sql)
          statements = normalized_sql.split(";").reject(&:blank?)
          statements.size > 1
        end

        # Detect subqueries in the SQL by checking for unbalanced parentheses
        # This is a heuristic method for feature detection.
        #
        # @param normalized_sql [String] Normalized SQL query
        # @return [Boolean] true if subqueries are likely present
        def detect_subqueries(normalized_sql)
          # Check if there are unbalanced parentheses that likely contain subqueries
          normalized_sql.count("(") > normalized_sql.count(")")
        end

        private

        # Check for comment injection attempts
        # Comments can be used to hide malicious SQL code
        #
        # @param sql [String] Raw SQL query
        # @return [Boolean] true if comment injection detected
        def has_comment_injection?(sql)
          ValidationConfig::SUSPICIOUS_PATTERNS[:comment_injection] =~ sql
        end

        # Check for string concatenation that might be used for injection
        # String concatenation can be used to build dynamic SQL attacks
        #
        # @param sql [String] Raw SQL query
        # @return [Boolean] true if suspicious string concatenation detected
        def has_string_concatenation?(sql)
          ValidationConfig::SUSPICIOUS_PATTERNS[:string_concatenation] =~ sql
        end

        # Check for excessive quotes which might indicate injection attempts
        # Large numbers of quotes can indicate SQL injection payload construction
        #
        # @param sql [String] Raw SQL query
        # @return [Boolean] true if excessive quotes detected
        def has_excessive_quotes?(sql)
          single_quotes = sql.count("'")
          double_quotes = sql.count('"')
          single_quotes > ValidationConfig::QUOTE_LIMIT ||
            double_quotes > ValidationConfig::QUOTE_LIMIT
        end

        # Check for hex encoding that might hide malicious code
        # Long hex strings can be used to encode SQL injection payloads
        #
        # @param sql [String] Raw SQL query
        # @return [Boolean] true if suspicious hex encoding detected
        def has_hex_encoding?(sql)
          ValidationConfig::SUSPICIOUS_PATTERNS[:hex_encoding] =~ sql
        end

        # Check for additional suspicious patterns
        # This method checks for newer and more sophisticated attack patterns
        #
        # @param sql [String] Raw SQL query
        # @return [Boolean] true if additional suspicious patterns detected
        def has_additional_suspicious_patterns?(sql)
          additional_patterns = [
            :char_function, :ascii_function, :substring_injection, :length_functions,
            :conditional_comments, :encoded_spaces, :multiple_unions, :nested_selects,
            :script_tags, :php_tags, :null_byte, :excessive_parentheses
          ]

          additional_patterns.any? do |pattern_name|
            ValidationConfig::SUSPICIOUS_PATTERNS[pattern_name] =~ sql
          end
        end
      end
    end
  end
end
