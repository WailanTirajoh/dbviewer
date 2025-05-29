module Dbviewer
  module Datatable
    # QueryOperations handles CRUD operations and data querying for database tables
    # It provides methods to fetch, filter and manipulate data in tables
    class QueryOperations
      attr_reader :connection, :adapter_name

      # Initialize with dependencies
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] The database connection
      # @param dynamic_model_factory [Dbviewer::Database::DynamicModelFactory] Factory for creating dynamic AR models
      # @param query_executor [Dbviewer::Query::Executor] Executor for raw SQL queries
      # @param table_metadata_manager [Dbviewer::Database::MetadataManager] Manager for table metadata
      def initialize(connection, dynamic_model_factory, query_executor, table_metadata_manager)
        @connection = connection
        @adapter_name = connection.adapter_name.downcase
        @dynamic_model_factory = dynamic_model_factory
        @query_executor = query_executor
        @table_metadata_manager = table_metadata_manager
        @query_analyzer = ::Dbviewer::Query::Analyzer.new(connection)
      end

      # Get the number of columns in a table
      # @param table_name [String] Name of the table
      # @return [Integer] Number of columns
      def column_count(table_name)
        table_columns(table_name).size
      end

      # Get records from a table with pagination and sorting
      # @param table_name [String] Name of the table
      # @param params [Dbviewer::Datatable::QueryParams] Query parameters object
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
      rescue => e
        Rails.logger.error("[DBViewer] Error executing table query: #{e.message}")
        raise e
      end

      # Get the total count of records in a table
      # @param table_name [String] Name of the table
      # @return [Integer] Number of records
      def table_count(table_name)
        get_model_for(table_name).count
      rescue => e
        Rails.logger.error("[DBViewer] Error counting records in table #{table_name}: #{e.message}")
        0
      end

      # Get the number of records in a table (alias for table_count)
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
        return table_count(table_name) unless column_filters.present?

        model = get_model_for(table_name)
        query = model.all

        # Apply filters in the same way as table_records
        query = apply_column_filters(query, table_name, column_filters)
        query.count
      rescue => e
        Rails.logger.error("[DBViewer] Error counting filtered records in table #{table_name}: #{e.message}")
        0
      end

      # Get column histogram/value distribution data for a specific column
      # @param table_name [String] Name of the table
      # @param column_name [String] Name of the column
      # @param limit [Integer] Maximum number of distinct values to return
      # @return [Array<Hash>] Array of value distribution data with labels and counts
      def fetch_column_distribution(table_name, column_name, limit = 20)
        return [] unless column_exists?(table_name, column_name)

        query = "SELECT #{column_name} as label, COUNT(*) as count FROM #{table_name}
                 WHERE #{column_name} IS NOT NULL
                 GROUP BY #{column_name}
                 ORDER BY count DESC LIMIT #{limit}"

        begin
          result = @connection.execute(query)
          adapter = @connection.adapter_name.downcase

          # Format depends on adapter
          if adapter =~ /mysql/
            result.to_a.map { |row| { label: row[0], value: row[1] } }
          elsif adapter =~ /sqlite/
            result.map { |row| { label: row["label"], value: row["count"] } }
          else # postgresql
            result.map { |row| { label: row["label"], value: row["count"] } }
          end
        rescue => e
          Rails.logger.error("Error fetching column distribution: #{e.message}")
          []
        end
      end

      # Get timestamp aggregation data for charts
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

      # Analyze query patterns and return performance recommendations
      # @param table_name [String] Name of the table
      # @param query_params [Dbviewer::Datatable::QueryParams] Query parameters
      # @return [Hash] Analysis results
      def analyze_query(table_name, query_params)
        @query_analyzer.analyze_query(table_name, query_params)
      end

      private

      # Apply column filters to a query
      # @param query [ActiveRecord::Relation] The query to apply filters to
      # @param table_name [String] Name of the table
      # @param column_filters [Hash] Hash of column_name => filter_value pairs
      # @return [ActiveRecord::Relation] The filtered query
      def apply_column_filters(query, table_name, column_filters)
        return query unless column_filters.present?

        # Create a copy of column_filters to modify without affecting the original
        filters = column_filters.dup

        # First check if we have a datetime range filter for created_at
        if filters["created_at"].present? &&
           filters["created_at_end"].present? &&
           column_exists?(table_name, "created_at")

          # Handle datetime range for created_at
          begin
            start_datetime = Time.parse(filters["created_at"].to_s)
            end_datetime = Time.parse(filters["created_at_end"].to_s)

            # Make sure end_datetime is at the end of the day/minute if it doesn't have time component
            if end_datetime.to_s.match(/00:00:00/)
              end_datetime = end_datetime.end_of_day
            end

            Rails.logger.info("[DBViewer] Applying date range filter on #{table_name}.created_at: #{start_datetime} to #{end_datetime}")

            # Use qualified column name for tables with schema
            column_name = "#{table_name}.created_at"

            # Different databases may require different SQL for datetime comparison
            adapter_name = connection.adapter_name.downcase

            if adapter_name =~ /mysql/
              query = query.where("#{column_name} BETWEEN ? AND ?", start_datetime, end_datetime)
            elsif adapter_name =~ /sqlite/
              # SQLite needs special handling for datetime format
              query = query.where("datetime(#{column_name}) BETWEEN datetime(?) AND datetime(?)", start_datetime, end_datetime)
            else # postgresql
              query = query.where("#{column_name} >= ? AND #{column_name} <= ?", start_datetime, end_datetime)
            end

            # Remove these from filters as they're handled above
            filters.delete("created_at")
            filters.delete("created_at_end")

          rescue => e
            Rails.logger.error("[DBViewer] Error parsing date range: #{e.message}")
            # Remove the problematic filters and continue
            filters.delete("created_at")
            filters.delete("created_at_end")
          end
        end

        # Apply remaining simple column filters
        filters.each do |column, value|
          next unless column_exists?(table_name, column)
          next if value.blank?

          column_sym = column.to_sym
          Rails.logger.debug("[DBViewer] Applying filter: #{column} = #{value}")

          # Handle different types of filtering
          if value.to_s.include?("%") || value.to_s.include?("*")
            # Pattern matching (LIKE operation)
            pattern = value.to_s.gsub("*", "%")
            query = query.where("#{column} LIKE ?", pattern)
          elsif value.to_s.start_with?(">=", "<=", ">", "<", "!=")
            # Comparison operators
            operator = value.to_s.match(/^(>=|<=|>|<|!=)/)[1]
            comparison_value = value.to_s.gsub(/^(>=|<=|>|<|!=)\s*/, "")

            case operator
            when ">="
              query = query.where("#{column} >= ?", comparison_value)
            when "<="
              query = query.where("#{column} <= ?", comparison_value)
            when ">"
              query = query.where("#{column} > ?", comparison_value)
            when "<"
              query = query.where("#{column} < ?", comparison_value)
            when "!="
              query = query.where("#{column} != ?", comparison_value)
            end
          else
            # Exact match
            query = query.where(column_sym => value)
          end
        end

        query
      end

      # Helper methods delegated to managers
      def get_model_for(table_name)
        @dynamic_model_factory.get_model_for(table_name)
      end

      def table_columns(table_name)
        @table_metadata_manager.table_columns(table_name)
      end

      def column_exists?(table_name, column_name)
        @table_metadata_manager.column_exists?(table_name, column_name)
      end

      def primary_key(table_name)
        @table_metadata_manager.primary_key(table_name)
      end
    end
  end
end
