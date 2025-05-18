module Dbviewer
  # QueryExecutor handles executing SQL queries and formatting results
  class QueryExecutor
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
      # Validate and normalize the SQL
      normalized_sql = ::Dbviewer::SqlValidator.validate!(sql.to_s)

      # Get max records from configuration
      max_records = @config.max_records || 10000

      # Add a safety limit if not already present
      unless normalized_sql =~ /\bLIMIT\s+\d+\s*$/i
        normalized_sql = "#{normalized_sql} LIMIT #{max_records}"
      end

      # Log and execute the query
      Rails.logger.debug("[DBViewer] Executing SQL query: #{normalized_sql}")
      start_time = Time.now
      result = @connection.exec_query(normalized_sql)
      duration = Time.now - start_time

      Rails.logger.debug("[DBViewer] Query completed in #{duration.round(2)}s, returned #{result.rows.size} rows")
      result
    rescue => e
      Rails.logger.error("[DBViewer] SQL query error: #{e.message} for query: #{sql}")
      raise e
    end

    # Execute a SQLite PRAGMA command without adding a LIMIT clause
    # @param pragma [String] PRAGMA command to execute (without the "PRAGMA" keyword)
    # @return [ActiveRecord::Result] Result set with the PRAGMA value
    # @raise [StandardError] If the query is invalid or cannot be executed
    def execute_sqlite_pragma(pragma)
      sql = "PRAGMA #{pragma}"
      Rails.logger.debug("[DBViewer] Executing SQLite pragma: #{sql}")
      result = @connection.exec_query(sql)
      Rails.logger.debug("[DBViewer] Pragma completed, returned #{result.rows.size} rows")
      result
    rescue => e
      Rails.logger.error("[DBViewer] SQLite pragma error: #{e.message} for pragma: #{pragma}")
      raise e
    end

    # Convert ActiveRecord::Relation to a standard result format
    # @param records [ActiveRecord::Relation] Records to convert
    # @param column_names [Array<String>] Column names
    # @return [ActiveRecord::Result] Result set with columns and rows
    def to_result_set(records, column_names)
      rows = records.map do |record|
        column_names.map do |col|
          # Handle serialized attributes
          value = record[col]
          serialize_if_needed(value)
        end
      end

      ActiveRecord::Result.new(column_names, rows)
    rescue => e
      Rails.logger.error("[DBViewer] Error converting to result set: #{e.message}")
      ActiveRecord::Result.new([], [])
    end

    private

    # Serialize complex objects for display
    # @param value [Object] Value to serialize
    # @return [String, Object] Serialized value or original value
    def serialize_if_needed(value)
      case value
      when Hash, Array
        value.to_json rescue value.to_s
      when Time, Date, DateTime
        value.to_s
      else
        value
      end
    end
  end
end
