require "dbviewer/error_handler"
require "dbviewer/table_query_params"

module Dbviewer
  # TableQueryOperations handles CRUD operations and data querying for database tables
  # It provides methods to fetch, filter and manipulate data in tables
  class TableQueryOperations
    attr_reader :connection, :adapter_name

    # Initialize with dependencies
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] The database connection
    # @param dynamic_model_factory [DynamicModelFactory] Factory for creating dynamic AR models
    # @param query_executor [QueryExecutor] Executor for raw SQL queries
    # @param table_metadata_manager [TableMetadataManager] Manager for table metadata
    def initialize(connection, dynamic_model_factory, query_executor, table_metadata_manager)
      @connection = connection
      @adapter_name = connection.adapter_name.downcase
      @dynamic_model_factory = dynamic_model_factory
      @query_executor = query_executor
      @table_metadata_manager = table_metadata_manager
    end

    # Get the number of columns in a table
    # @param table_name [String] Name of the table
    # @return [Integer] Number of columns
    def column_count(table_name)
      table_columns(table_name).size
    end

    # Get records from a table with pagination and sorting
    # @param table_name [String] Name of the table
    # @param params [TableQueryParams] Query parameters object
    # @return [ActiveRecord::Result] Result set with columns and rows
    def table_records(table_name, params)
      model = get_model_for(table_name)
      query = model.all

      # Apply column filters if provided
      query = apply_column_filters(query, table_name, params.column_filters)

      # Apply sorting if provided
      if params.order_by.present? && column_exists?(table_name, params.order_by)
        query = query.order("#{connection.quote_column_name(params.order_by)} #{params.direction}")
      end

      # Apply pagination
      records = query.limit(params.per_page).offset((params.page - 1) * params.per_page)

      # Get column names for consistent ordering
      column_names = table_columns(table_name).map { |c| c[:name] }

      # Format results
      @query_executor.to_result_set(records, column_names)
    end

    # Get the total count of records in a table
    # @param table_name [String] Name of the table
    # @return [Integer] Number of records
    def table_count(table_name)
      model = get_model_for(table_name)
      model.count
    end

    # Alias for table_count
    # @param table_name [String] Name of the table
    # @return [Integer] Number of records
    def record_count(table_name)
      table_count(table_name)
    end

    # Get the number of records in a table with filters applied
    # @param table_name [String] Name of the table
    # @param column_filters [Hash] Hash of column_name => filter_value for filtering
    # @return [Integer] Number of filtered records
    def filtered_record_count(table_name, column_filters = {})
      model = get_model_for(table_name)
      query = model.all

      # Apply column filters if provided
      query = apply_column_filters(query, table_name, column_filters)

      query.count
    end

    # Execute a raw SQL query after validating for safety
    # @param sql [String] SQL query to execute
    # @return [ActiveRecord::Result] Result set with columns and rows
    # @raise [StandardError] If the query is invalid or unsafe
    def execute_query(sql)
      @query_executor.execute_query(sql)
    end

    # Execute a SQLite PRAGMA command without adding a LIMIT clause
    # @param pragma [String] PRAGMA command to execute (without the "PRAGMA" keyword)
    # @return [ActiveRecord::Result] Result set with the PRAGMA value
    # @raise [StandardError] If the query is invalid or cannot be executed
    def execute_sqlite_pragma(pragma)
      @query_executor.execute_sqlite_pragma(pragma)
    end

    # Query a table with more granular control using ActiveRecord
    # @param table_name [String] Name of the table
    # @param select [String, Array] Columns to select
    # @param order [String, Hash] Order by clause
    # @param limit [Integer] Maximum number of records to return
    # @param offset [Integer] Offset from which to start returning records
    # @param where [String, Hash] Where conditions
    # @return [ActiveRecord::Result] Result set with columns and rows
    def query_table(table_name, select: nil, order: nil, limit: nil, offset: nil, where: nil, max_records: 1000)
      model = get_model_for(table_name)
      query = model.all

      query = query.select(select) if select.present?
      query = query.where(where) if where.present?
      query = query.order(order) if order.present?

      # Apply safety limit
      query = query.limit([ limit || max_records, max_records ].min)
      query = query.offset(offset) if offset.present?

      # Get column names for the result set
      column_names = if select.is_a?(Array)
        select
      elsif select.is_a?(String) && !select.include?("*")
        select.split(",").map(&:strip)
      else
        table_columns(table_name).map { |c| c[:name] }
      end

      @query_executor.to_result_set(query, column_names)
    end

    # Fetch timestamp data for visualization
    # @param table_name [String] Name of the table
    # @param grouping [String] Grouping type (hourly, daily, weekly, monthly)
    # @param column [String] Timestamp column name (defaults to created_at)
    # @return [Array<Hash>] Array of timestamp data with labels and counts
    def fetch_timestamp_data(table_name, grouping = "daily", column = "created_at")
      return [] unless column_exists?(table_name, column)

      adapter = @connection.adapter_name.downcase

      date_format = case grouping
      when "hourly"
        if adapter =~ /mysql/
          "DATE_FORMAT(#{column}, '%Y-%m-%d %H:00')"
        elsif adapter =~ /sqlite/
          "strftime('%Y-%m-%d %H:00', #{column})"
        else # postgresql
          "TO_CHAR(#{column}, 'YYYY-MM-DD HH24:00')"
        end
      when "weekly"
        if adapter =~ /mysql/
          "DATE_FORMAT(#{column}, '%Y-%v')"
        elsif adapter =~ /sqlite/
          "strftime('%Y-%W', #{column})"
        else # postgresql
          "TO_CHAR(#{column}, 'YYYY-IW')"
        end
      when "monthly"
        if adapter =~ /mysql/
          "DATE_FORMAT(#{column}, '%Y-%m')"
        elsif adapter =~ /sqlite/
          "strftime('%Y-%m', #{column})"
        else # postgresql
          "TO_CHAR(#{column}, 'YYYY-MM')"
        end
      else # daily is default
        if adapter =~ /mysql/
          "DATE(#{column})"
        elsif adapter =~ /sqlite/
          "date(#{column})"
        else # postgresql
                        "DATE(#{column})"
        end
      end

      # Query works the same for all database adapters
      query = "SELECT #{date_format} as label, COUNT(*) as count FROM #{table_name}
               WHERE #{column} IS NOT NULL
               GROUP BY label
               ORDER BY MIN(#{column}) DESC LIMIT 30"

      begin
        result = @connection.execute(query)

        # Format depends on adapter
        if adapter =~ /mysql/
          result.to_a.map { |row| { label: row[0], value: row[1] } }
        elsif adapter =~ /sqlite/
          result.map { |row| { label: row["label"], value: row["count"] } }
        else # postgresql
          result.map { |row| { label: row["label"], value: row["count"] } }
        end
      rescue => e
        Rails.logger.error("Error fetching timestamp data: #{e.message}")
        []
      end
    end

    private

    # Apply column filters to a query
    # @param query [ActiveRecord::Relation] The query to apply filters to
    # @param table_name [String] Name of the table
    # @param column_filters [Hash] Hash of column_name => filter_value pairs
    # @return [ActiveRecord::Relation] The filtered query
    def apply_column_filters(query, table_name, column_filters)
      return query unless column_filters.present?

      column_filters.each do |column, value|
        # Skip operator entries (they'll be handled with their corresponding value)
        next if column.to_s.end_with?("_operator")
        next if value.blank?
        next unless column_exists?(table_name, column)

        # Get operator if available, otherwise use default
        operator = column_filters["#{column}_operator"]

        query = apply_column_filter(query, column, value, table_name, operator)
      end

      query
    end

    # Get a dynamic AR model for a table
    # @param table_name [String] Name of the table
    # @return [Class] ActiveRecord model class
    def get_model_for(table_name)
      @dynamic_model_factory.get_model_for(table_name)
    end

    # Get column information for a table
    # @param table_name [String] Name of the table
    # @return [Array<Hash>] List of column info hashes
    def table_columns(table_name)
      @table_metadata_manager.table_columns(table_name)
    end

    # Check if column exists in table
    # @param table_name [String] Name of the table
    # @param column_name [String] Name of the column
    # @return [Boolean] True if column exists
    def column_exists?(table_name, column_name)
      @table_metadata_manager.column_exists?(table_name, column_name)
    end

    # Helper method to apply column filters to a query
    # @param query [ActiveRecord::Relation] The query to apply filters to
    # @param column [String] The column name to filter on
    # @param value [String] The value to filter by
    # @param table_name [String] The name of the table being queried
    # @param operator [String] The operator to use for filtering (eq, neq, lt, gt, etc.)
    # @return [ActiveRecord::Relation] The filtered query
    def apply_column_filter(query, column, value, table_name, operator = nil)
      column_info = table_columns(table_name).find { |c| c[:name] == column }
      return query unless column_info

      column_type = column_info[:type].to_s
      quoted_column = connection.quote_column_name(column)

      # Default to appropriate operator if none specified or "default" value is used
      operator = default_operator_for_type(column_type) if operator.nil? || operator == "default"

      # Detect the column type for appropriate filtering
      if datetime_type?(column_type)
        filter_datetime_column(query, quoted_column, value, operator)
      elsif date_type?(column_type)
        filter_date_column(query, quoted_column, value, operator)
      elsif time_type?(column_type)
        filter_time_column(query, quoted_column, value, operator)
      elsif numeric_type?(column_type)
        filter_numeric_column(query, quoted_column, value, operator)
      elsif string_type?(column_type)
        filter_string_column(query, quoted_column, value, operator)
      else
        # For unknown types, try numeric filter if value is numeric, otherwise string filter
        numeric_pattern = /\A[+-]?\d+(\.\d+)?\z/
        if value =~ numeric_pattern
          filter_numeric_column(query, quoted_column, value, operator)
        else
          filter_string_column(query, quoted_column, value, operator)
        end
      end
    end

    # Determine if column is a datetime type
    # @param column_type [String] The column type from database
    # @return [Boolean] True if datetime type
    def datetime_type?(column_type)
      column_type =~ /datetime|timestamp/i
    end

    # Determine if column is a date type
    # @param column_type [String] The column type from database
    # @return [Boolean] True if date type
    def date_type?(column_type)
      column_type =~ /^date$/i
    end

    # Determine if column is a time type
    # @param column_type [String] The column type from database
    # @return [Boolean] True if time type
    def time_type?(column_type)
      column_type =~ /^time$/i
    end

    # Determine if column is a numeric type
    # @param column_type [String] The column type from database
    # @return [Boolean] True if numeric type
    def numeric_type?(column_type)
      column_type =~ /int|float|decimal|double|number|numeric|real|money|bigint|smallint|tinyint|mediumint|bit/i
    end

    # Determine if column is a string type
    # @param column_type [String] The column type from database
    # @return [Boolean] True if string type
    def string_type?(column_type)
      column_type =~ /char|text|string|uuid|enum/i
    end

    # Get default operator based on column type
    # @param column_type [String] The column type from database
    # @return [String] The default operator
    def default_operator_for_type(column_type)
      if string_type?(column_type)
        "contains"
      else
        "eq"
      end
    end

    # Apply comparison operator to query
    # @param query [ActiveRecord::Relation] The query
    # @param column [String] The quoted column name
    # @param value [Object] The value to compare
    # @param operator [String] The operator
    # @return [ActiveRecord::Relation] The modified query
    def apply_comparison_operator(query, column, value, operator)
      case operator
      when "eq"
        query.where("#{column} = ?", value)
      when "neq"
        query.where("#{column} != ?", value)
      when "lt"
        query.where("#{column} < ?", value)
      when "gt"
        query.where("#{column} > ?", value)
      when "lte"
        query.where("#{column} <= ?", value)
      when "gte"
        query.where("#{column} >= ?", value)
      else
        # Default to equality
        query.where("#{column} = ?", value)
      end
    end

    # Apply string comparison operator
    # @param query [ActiveRecord::Relation] The query
    # @param column [String] The quoted column name
    # @param value [String] The string value to compare
    # @param operator [String] The operator
    # @return [ActiveRecord::Relation] The modified query
    def apply_string_operator(query, column, value, operator)
      case operator
      when "contains"
        query.where("#{column} LIKE ?", "%#{value}%")
      when "not_contains"
        query.where("#{column} NOT LIKE ?", "%#{value}%")
      when "eq"
        query.where("#{column} = ?", value)
      when "neq"
        query.where("#{column} != ?", value)
      when "starts_with"
        query.where("#{column} LIKE ?", "#{value}%")
      when "ends_with"
        query.where("#{column} LIKE ?", "%#{value}")
      else
        # Default to contains
        query.where("#{column} LIKE ?", "%#{value}%")
      end
    end

    # Filter datetime column
    # @param query [ActiveRecord::Relation] The query
    # @param quoted_column [String] The quoted column name
    # @param value [String] The value to filter by
    # @param operator [String] The operator
    # @return [ActiveRecord::Relation] The modified query
    def filter_datetime_column(query, quoted_column, value, operator)
      begin
        parsed_date = Time.parse(value.to_s)
        apply_comparison_operator(query, quoted_column, parsed_date, operator)
      rescue => e
        Rails.logger.debug("[DBViewer] Failed to parse datetime: #{e.message}")
        # Fallback to string comparison if parsing fails
        query.where("CAST(#{quoted_column} AS CHAR) LIKE ?", "%#{value}%")
      end
    end

    # Filter date column
    # @param query [ActiveRecord::Relation] The query
    # @param quoted_column [String] The quoted column name
    # @param value [String] The value to filter by
    # @param operator [String] The operator
    # @return [ActiveRecord::Relation] The modified query
    def filter_date_column(query, quoted_column, value, operator)
      begin
        parsed_date = Date.parse(value.to_s)
        apply_comparison_operator(query, quoted_column, parsed_date, operator)
      rescue => e
        Rails.logger.debug("[DBViewer] Failed to parse date: #{e.message}")
        # Fallback to string comparison if parsing fails
        query.where("CAST(#{quoted_column} AS CHAR) LIKE ?", "%#{value}%")
      end
    end

    # Filter time column
    # @param query [ActiveRecord::Relation] The query
    # @param quoted_column [String] The quoted column name
    # @param value [String] The value to filter by
    # @param operator [String] The operator
    # @return [ActiveRecord::Relation] The modified query
    def filter_time_column(query, quoted_column, value, operator)
      begin
        parsed_time = Time.parse(value.to_s)
        formatted_time = parsed_time.strftime("%H:%M:%S")

        # Prepare time expression based on database adapter
        time_expr = get_time_expression(quoted_column)

        apply_comparison_operator(query, time_expr, formatted_time, operator)
      rescue => e
        Rails.logger.debug("[DBViewer] Failed to parse time: #{e.message}")
        # Fallback to string comparison if parsing fails
        query.where("CAST(#{quoted_column} AS CHAR) LIKE ?", "%#{value}%")
      end
    end

    # Get the appropriate time expression based on database adapter
    # @param quoted_column [String] The quoted column name
    # @return [String] The time expression
    def get_time_expression(quoted_column)
      if @adapter_name =~ /mysql/
        "TIME(#{quoted_column})"
      elsif @adapter_name =~ /postgresql/
        "CAST(#{quoted_column} AS TIME)"
      else
        # SQLite and others
        quoted_column
      end
    end

    # Filter numeric column
    # @param query [ActiveRecord::Relation] The query
    # @param quoted_column [String] The quoted column name
    # @param value [String] The value to filter by
    # @param operator [String] The operator
    # @return [ActiveRecord::Relation] The modified query
    def filter_numeric_column(query, quoted_column, value, operator)
      numeric_pattern = /\A[+-]?\d+(\.\d+)?\z/

      if value =~ numeric_pattern
        # Convert to proper numeric type for comparison
        numeric_value = value.include?(".") ? value.to_f : value.to_i
        Rails.logger.debug("[DBViewer] Converting value #{value} to numeric: #{numeric_value}")

        apply_comparison_operator(query, quoted_column, numeric_value, operator)
      else
        # Non-numeric value for numeric column, try string comparison
        filter_non_numeric_value(query, quoted_column, value, operator)
      end
    end

    # Filter non-numeric value for numeric column
    # @param query [ActiveRecord::Relation] The query
    # @param quoted_column [String] The quoted column name
    # @param value [String] The value to filter by
    # @param operator [String] The operator
    # @return [ActiveRecord::Relation] The modified query
    def filter_non_numeric_value(query, quoted_column, value, operator)
      case operator
      when "contains", "starts_with", "ends_with"
        query.where("CAST(#{quoted_column} AS CHAR) LIKE ?", "%#{value}%")
      when "not_contains"
        query.where("CAST(#{quoted_column} AS CHAR) NOT LIKE ?", "%#{value}%")
      when "eq"
        query.where("CAST(#{quoted_column} AS CHAR) = ?", value)
      when "neq"
        query.where("CAST(#{quoted_column} AS CHAR) != ?", value)
      else
        # Default to contains
        query.where("CAST(#{quoted_column} AS CHAR) LIKE ?", "%#{value}%")
      end
    end

    # Filter string column
    # @param query [ActiveRecord::Relation] The query
    # @param quoted_column [String] The quoted column name
    # @param value [String] The value to filter by
    # @param operator [String] The operator
    # @return [ActiveRecord::Relation] The modified query
    def filter_string_column(query, quoted_column, value, operator)
      apply_string_operator(query, quoted_column, value, operator)
    end
  end
end
