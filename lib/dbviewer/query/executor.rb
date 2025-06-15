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
        exec_query(normalize_sql(sql))
      end

      # Execute a SQLite PRAGMA command without adding a LIMIT clause
      # @param pragma [String] PRAGMA command to execute (without the "PRAGMA" keyword)
      # @return [ActiveRecord::Result] Result set with the PRAGMA value
      # @raise [StandardError] If the query is invalid or cannot be executed
      def execute_sqlite_pragma(pragma)
        exec_query("PRAGMA #{pragma}")
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
    end
  end
end
