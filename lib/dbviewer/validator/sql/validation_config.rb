# frozen_string_literal: true

module Dbviewer
  module Validator
    class Sql
      # Configuration constants and patterns for SQL validation
      # This module centralizes all security-related patterns and rules
      # used throughout the validation process.
      module ValidationConfig
        # List of SQL keywords that could modify data or schema
        # These keywords are completely forbidden in user queries
        FORBIDDEN_KEYWORDS = %w[
          UPDATE INSERT DELETE DROP ALTER CREATE TRUNCATE REPLACE
          RENAME GRANT REVOKE LOCK UNLOCK COMMIT ROLLBACK
          SAVEPOINT INTO CALL EXECUTE EXEC
        ].freeze

        # List of SQL keywords that should only be allowed in specific contexts
        # These are monitored but not automatically blocked
        CONDITIONAL_KEYWORDS = {
          # JOIN is allowed, but we should check for suspicious patterns
          "JOIN" => /\bJOIN\b/i,
          # UNION is allowed, but potential for injection
          "UNION" => /\bUNION\b/i,
          # WITH is allowed for CTEs, but need to ensure it's not a data modification
          "WITH" => /\bWITH\b/i
        }.freeze

        # Maximum allowed query length (can be overridden by configuration)
        DEFAULT_MAX_QUERY_LENGTH = 10000

        # Patterns for detecting suspicious content that might indicate attacks
        SUSPICIOUS_PATTERNS = {
          comment_injection: /\s+--|\/\*/,
          string_concatenation: /\|\||CONCAT\s*\(/i,
          hex_encoding: /0x[0-9a-f]{16,}/i
        }.freeze

        # SQL injection attack patterns - these are definitive threats
        INJECTION_PATTERNS = {
          basic_or_injection: /'\s*OR\s*'.*'\s*=\s*'/i,
          quoted_or_equals: /'\s*OR\s*1\s*=\s*1/i,
          unquoted_or_equals: /\s+OR\s+1\s*=\s*1/i,
          comment_termination: /'\s*;\s*--/i,
          version_detection: /@@version/i,
          version_function: /version\(\)/i,
          file_access: /\bLOAD_FILE\s*\(/i,
          outfile_access: /\bINTO\s+OUTFILE\b/i,
          dumpfile_access: /\bINTO\s+DUMPFILE\b/i
        }.freeze

        # Database feature detection patterns for query analysis
        FEATURE_PATTERNS = {
          join: /\b(INNER|LEFT|RIGHT|FULL|CROSS)?\s*JOIN\b/i,
          order_by: /\bORDER\s+BY\b/i,
          group_by: /\bGROUP\s+BY\b/i,
          having: /\bHAVING\b/i,
          union: /\bUNION\b/i,
          window_function: /\bOVER\s*\(/i
        }.freeze

        # Thresholds for suspicious activity detection
        QUOTE_LIMIT = 20 # Maximum number of quotes before flagging as suspicious
        HEX_MIN_LENGTH = 16 # Minimum hex string length to be considered suspicious

        # PRAGMA statement pattern for SQLite introspection
        PRAGMA_PATTERN = /\A\s*PRAGMA\s+[a-z0-9_]+(\([^)]*\))?\s*\z/i

        # Valid query start patterns (SELECT or WITH for CTEs)
        VALID_QUERY_START_PATTERN = /\A\s*(SELECT|WITH)\s+/i
      end
    end
  end
end
