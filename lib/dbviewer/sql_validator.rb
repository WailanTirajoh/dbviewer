module Dbviewer
  # SqlValidator class handles SQL query validation and normalization
  # to ensure queries are safe (read-only) and properly formatted
  class SqlValidator
    # List of SQL keywords that could modify data or schema
    FORBIDDEN_KEYWORDS = %w(
      UPDATE INSERT DELETE DROP ALTER CREATE TRUNCATE REPLACE
      RENAME GRANT REVOKE LOCK UNLOCK COMMIT ROLLBACK
    )

    # Determines if a query is safe (read-only)
    # @param sql [String] The SQL query to validate
    # @return [Boolean] true if the query is safe, false otherwise
    def self.safe_query?(sql)
      normalized_sql = normalize(sql)

      # Case-insensitive check for SELECT at the beginning
      return false unless normalized_sql =~ /\A\s*SELECT\s+/i

      # Check for forbidden keywords that might be used in subqueries or other SQL constructs
      FORBIDDEN_KEYWORDS.each do |keyword|
        # Look for the keyword with word boundaries to avoid false positives
        return false if normalized_sql =~ /\b#{keyword}\b/i
      end

      true
    end

    # Normalize SQL by removing comments and extra whitespace
    # @param sql [String] The SQL query to normalize
    # @return [String] The normalized SQL query
    def self.normalize(sql)
      return "" if sql.nil?

      # Remove SQL comments (both -- and /* */ styles)
      sql = sql.gsub(/--.*$/, '')             # Remove -- style comments
              .gsub(/\/\*.*?\*\//m, '')       # Remove /* */ style comments
              .gsub(/\s+/, ' ')               # Normalize whitespace
              .strip                          # Remove leading/trailing whitespace

      sql
    end

    # Validates a query and raises an exception if it's unsafe
    # @param sql [String] The SQL query to validate
    # @raise [StandardError] if the query is unsafe
    # @return [String] The normalized SQL query if it's safe
    def self.validate!(sql)
      normalized_sql = normalize(sql)

      unless safe_query?(normalized_sql)
        raise "Only SELECT queries are allowed for security reasons"
      end

      normalized_sql
    end
  end
end
