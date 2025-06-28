module Dbviewer
  module Query
    # Executor handles executing SQL queries and formatting results
    class Executor
      # Initialize with a connection and configuration
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param config [Dbviewer::Configuration] Configuration object
      def initialize(connection, config = nil)
        @connection = connection
        @config = config || Dbviewer.configuration
      end

      # Execute a raw SQL query after validating for safety
      # @param sql [String] SQL query to execute
      # @return [ActiveRecord::Result] Result set with columns and rows
      # @raise [StandardError] If the query is invalid or unsafe
      def execute_query(sql)
        log_query_execution(sql, "query")
        exec_query(normalize_sql(sql))
      end

      # Execute a SQLite PRAGMA command without adding a LIMIT clause
      # @param pragma [String] PRAGMA command to execute (without the "PRAGMA" keyword)
      # @return [ActiveRecord::Result] Result set with the PRAGMA value
      # @raise [StandardError] If the query is invalid or cannot be executed
      def execute_sqlite_pragma(pragma)
        pragma_sql = "PRAGMA #{pragma}"
        log_query_execution(pragma_sql, "pragma")
        exec_query(pragma_sql)
      end

      private

      def exec_query(sql)
        @connection.exec_query(sql)
      end

      def normalize_sql(sql)
        normalized_sql = ::Dbviewer::Validator::Sql.validate!(sql.to_s)
        max_records = @config.max_records || 10000
        normalized_sql = "#{normalized_sql} LIMIT #{max_records}" unless normalized_sql =~ /\bLIMIT\s+\d+\s*$/i
        normalized_sql
      end

      # Log query execution for security monitoring
      # @param sql [String] The SQL query being executed
      # @param query_type [String] Type of query (query, pragma, etc.)
      def log_query_execution(sql, query_type)
        return unless should_log_queries?

        ::Dbviewer::Query::Logger.log_security_event(
          event_type: "query_execution",
          query_type: query_type,
          sql: sql,
          timestamp: Time.current
        )
      end

      def should_log_queries?
        @config.respond_to?(:log_queries) ? @config.log_queries : true
      end
    end
  end
end
