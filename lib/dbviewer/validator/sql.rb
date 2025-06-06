# frozen_string_literal: true

module Dbviewer
  module Validator
    # Sql class handles SQL query validation and normalization
    # to ensure queries are safe (read-only) and properly formatted.
    # This helps prevent potentially destructive SQL operations.
    class Sql
      # List of SQL keywords that could modify data or schema
      FORBIDDEN_KEYWORDS = %w[
        UPDATE INSERT DELETE DROP ALTER CREATE TRUNCATE REPLACE
        RENAME GRANT REVOKE LOCK UNLOCK COMMIT ROLLBACK
        SAVEPOINT INTO CALL EXECUTE EXEC
      ]

      # List of SQL keywords that should only be allowed in specific contexts
      CONDITIONAL_KEYWORDS = {
        # JOIN is allowed, but we should check for suspicious patterns
        "JOIN" => /\bJOIN\b/i,
        # UNION is allowed, but potential for injection
        "UNION" => /\bUNION\b/i,
        # WITH is allowed for CTEs, but need to ensure it's not a data modification
        "WITH" => /\bWITH\b/i
      }

      # Maximum allowed query length
      MAX_QUERY_LENGTH = 10000

      # Determines if a query is safe (read-only)
      # @param sql [String] The SQL query to validate
      # @return [Boolean] true if the query is safe, false otherwise
      def self.safe_query?(sql)
        return false if sql.blank?

        # Get max query length from configuration
        max_length = Dbviewer.configuration.max_query_length || MAX_QUERY_LENGTH
        return false if sql.length > max_length

        normalized_sql = normalize(sql)

        # Case-insensitive check for SELECT at the beginning
        return false unless normalized_sql =~ /\A\s*SELECT\s+/i

        # Check for forbidden keywords that might be used in subqueries or other SQL constructs
        FORBIDDEN_KEYWORDS.each do |keyword|
          # Look for the keyword with word boundaries to avoid false positives
          return false if normalized_sql =~ /\b#{keyword}\b/i
        end

        # Check for suspicious patterns that might indicate SQL injection attempts
        return false if has_suspicious_patterns?(normalized_sql)

        # Check for multiple statements (;) which could allow executing multiple commands
        statements = normalized_sql.split(";").reject(&:blank?)
        return false if statements.size > 1

        # Additional specific checks for common SQL injection patterns
        return false if has_injection_patterns?(normalized_sql)

        true
      end

      # Check for suspicious patterns in SQL that might indicate an attack
      # @param sql [String] Normalized SQL query
      # @return [Boolean] true if suspicious patterns found, false otherwise
      def self.has_suspicious_patterns?(sql)
        # Check for SQL comment sequences that might be used to hide malicious code
        return true if sql =~ /\s+--/ || sql =~ /\/\*/

        # Check for string concatenation which might be used for injection
        return true if sql =~ /\|\|/ || sql =~ /CONCAT\s*\(/i

        # Check for excessive number of quotes which might indicate injection
        single_quotes = sql.count("'")
        double_quotes = sql.count('"')
        return true if single_quotes > 20 || double_quotes > 20

        # Check for hex/binary data which might hide malicious code
        return true if sql =~ /0x[0-9a-f]{16,}/i

        false
      end

      # Check for specific SQL injection patterns
      # @param sql [String] Normalized SQL query
      # @return [Boolean] true if injection patterns found, false otherwise
      def self.has_injection_patterns?(sql)
        # Check for typical SQL injection test patterns
        return true if sql =~ /'\s*OR\s*'.*'\s*=\s*'/i
        return true if sql =~ /'\s*OR\s*1\s*=\s*1/i
        return true if sql =~ /'\s*;\s*--/i

        # Check for attempts to determine database type
        return true if sql =~ /@@version/i
        return true if sql =~ /version\(\)/i

        false
      end

      # Normalize SQL by removing comments and extra whitespace
      # @param sql [String] The SQL query to normalize
      # @return [String] The normalized SQL query
      def self.normalize(sql)
        return "" if sql.nil?

        begin
          # Remove SQL comments (both -- and /* */ styles)
          normalized = sql.gsub(/--.*$/, "")             # Remove -- style comments
                  .gsub(/\/\*.*?\*\//m, "")       # Remove /* */ style comments
                  .gsub(/\s+/, " ")               # Normalize whitespace
                  .strip                          # Remove leading/trailing whitespace

          # Replace multiple spaces with a single space
          normalized.gsub(/\s{2,}/, " ")
        rescue => e
          Rails.logger.error("[DBViewer] SQL normalization error: #{e.message}")
          ""
        end
      end

      # Validates a query and raises an exception if it's unsafe
      # @param sql [String] The SQL query to validate
      # @raise [SecurityError] if the query is unsafe
      # @return [String] The normalized SQL query if it's safe
      def self.validate!(sql)
        if sql.blank?
          raise SecurityError, "Empty query is not allowed"
        end

        # Get max query length from configuration
        max_length = Dbviewer.configuration.max_query_length || MAX_QUERY_LENGTH
        if sql.length > max_length
          raise SecurityError, "Query exceeds maximum allowed length (#{max_length} chars)"
        end

        normalized_sql = normalize(sql)

        # Special case for SQLite PRAGMA statements which are safe read-only commands
        if normalized_sql =~ /\A\s*PRAGMA\s+[a-z0-9_]+\s*\z/i
          return normalized_sql
        end

        unless normalized_sql =~ /\A\s*SELECT\s+/i
          raise SecurityError, "Query must begin with SELECT for security reasons"
        end

        FORBIDDEN_KEYWORDS.each do |keyword|
          if normalized_sql =~ /\b#{keyword}\b/i
            raise SecurityError, "Forbidden keyword '#{keyword}' detected in query"
          end
        end

        if has_suspicious_patterns?(normalized_sql)
          raise SecurityError, "Query contains suspicious patterns that may indicate SQL injection"
        end

        # Check for multiple statements
        statements = normalized_sql.split(";").reject(&:blank?)
        if statements.size > 1
          raise SecurityError, "Multiple SQL statements are not allowed"
        end

        if has_injection_patterns?(normalized_sql)
          raise SecurityError, "Query contains patterns commonly associated with SQL injection attempts"
        end

        normalized_sql
      end

      # Check if a query is using a specific database feature that might need special handling
      # @param sql [String] The SQL query
      # @param feature [Symbol] The feature to check for (:join, :subquery, :order_by, etc.)
      # @return [Boolean] true if the feature is used in the query
      def self.uses_feature?(sql, feature)
        normalized = normalize(sql)
        case feature
        when :join
          normalized =~ /\b(INNER|LEFT|RIGHT|FULL|CROSS)?\s*JOIN\b/i
        when :subquery
          # Check if there are parentheses that likely contain a subquery
          normalized.count("(") > normalized.count(")")
        when :order_by
          normalized =~ /\bORDER\s+BY\b/i
        when :group_by
          normalized =~ /\bGROUP\s+BY\b/i
        when :having
          normalized =~ /\bHAVING\b/i
        when :union
          normalized =~ /\bUNION\b/i
        when :window_function
          normalized =~ /\bOVER\s*\(/i
        else
          false
        end
      end
    end
  end
end
