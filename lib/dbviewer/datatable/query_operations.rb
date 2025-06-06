module Dbviewer
  module Datatable
    # QueryOperations handles CRUD operations and data querying for database tables
    # It provides methods to fetch, filter and manipulate data in tables
    class QueryOperations
      attr_reader :connection, :adapter_name

      # Initialize with dependencies
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] The database connection
      # @param dynamic_model_factory [Dbviewer::Database::DynamicModelFactory] Factory for creating dynamic AR models
      # @param table_metadata_manager [Dbviewer::Database::MetadataManager] Manager for table metadata
      def initialize(connection, dynamic_model_factory, table_metadata_manager)
        @connection = connection
        @adapter_name = connection.adapter_name.downcase
        @dynamic_model_factory = dynamic_model_factory
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
        to_result_set(records, column_names)
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

      ## -- Delegator

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

        column_filters.each do |column, value|
          query = apply_single_column_filter(query, table_name, column, value, column_filters)
        end

        query
      end

      # Apply a single column filter to a query
      # @param query [ActiveRecord::Relation] The query to apply the filter to
      # @param table_name [String] Name of the table
      # @param column [String] The column name
      # @param value [String] The filter value
      # @param column_filters [Hash] All column filters for accessing operator
      # @return [ActiveRecord::Relation] The filtered query
      def apply_single_column_filter(query, table_name, column, value, column_filters)
        return query unless column_exists?(table_name, column)
        return query if column.end_with?("_operator")

        operator = column_filters["#{column}_operator"]

        if special_operators(query)[operator]
          return special_operators(query)[operator].call(column)
        end
        return query if value.blank?

        if operator && operator_handlers(query)[operator]
          return operator_handlers(query)[operator].call(column, value)
        else
          # Default to eq no specific operator is provided
          return query.where("#{column} = ?", value)
        end

        query
      end

      def special_operators(query)
        {
          "is_null" => ->(column) {  query.where("#{column} IS NULL") },
          "is_not_null" => ->(column) { query.where("#{column} IS NOT NULL") }
        }
      end

      def operator_handlers(query)
        {
          "contains" => ->(column, value) { query.where("#{column} LIKE ?", "%#{value}%") },
          "not_contain" => ->(column, value) { query.where("#{column} NOT LIKE ?", "%#{value}%") },
          "starts_with" => ->(column, value) { query.where("#{column} LIKE ?", "#{value}%") },
          "ends_with" => ->(column, value) { query.where("#{column} LIKE ?", "%#{value}") },
          "equals" => ->(column, value) { query.where(column.to_sym => value) },
          "eq" => ->(column, value) { query.where("#{column} = ?", value) },
          "gte" => ->(column, value) { query.where("#{column} >= ?", value) },
          "lte" => ->(column, value) { query.where("#{column} <= ?", value) },
          "gt" => ->(column, value) { query.where("#{column} > ?", value) },
          "lt" => ->(column, value) { query.where("#{column} < ?", value) },
          "neq" => ->(column, value) { query.where("#{column} != ?", value) }
        }
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
end
