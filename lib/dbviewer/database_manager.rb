require "dbviewer/cache_manager"
require "dbviewer/table_metadata_manager"
require "dbviewer/dynamic_model_factory"
require "dbviewer/query_executor"
require "dbviewer/error_handler"

module Dbviewer
  # DatabaseManager handles all database interactions for the DBViewer engine
  # It provides methods to access database structure and data
  class DatabaseManager
    attr_reader :connection, :adapter_name

    # Initialize the database manager
    def initialize
      ensure_connection
      @cache_manager = CacheManager.new(self.class.configuration)
      @table_metadata_manager = TableMetadataManager.new(@connection, @cache_manager)
      @dynamic_model_factory = DynamicModelFactory.new(@connection, @cache_manager)
      @query_executor = QueryExecutor.new(@connection, self.class.configuration)
      reset_cache_if_needed
    end

    # Get configuration from class method or Dbviewer
    def self.configuration
      Dbviewer.configuration
    end

    # Get default per page from configuration
    def self.default_per_page
      configuration.default_per_page
    end

    # Get max records from configuration
    def self.max_records
      configuration.max_records
    end

    # Get cache expiry from configuration
    def self.cache_expiry
      configuration.cache_expiry
    end

    # Returns a sorted list of all tables in the database
    # @return [Array<String>] List of table names
    def tables
      @table_metadata_manager.tables
    end

    # Returns column information for a specific table
    # @param table_name [String] Name of the table
    # @return [Array<Hash>] List of column details with name, type, null, default
    def table_columns(table_name)
      @table_metadata_manager.table_columns(table_name)
    end

    # Get detailed metadata about a table (primary keys, indexes, foreign keys)
    # @param table_name [String] Name of the table
    # @return [Hash] Table metadata
    def table_metadata(table_name)
      @table_metadata_manager.table_metadata(table_name)
    end

    # Get the total count of records in a table
    # @param table_name [String] Name of the table
    # @return [Integer] Number of records
    def table_count(table_name)
      model = get_model_for(table_name)
      model.count
    end

    # Get records from a table with pagination and sorting
    # @param table_name [String] Name of the table
    # @param page [Integer] Page number (1-based)
    # @param order_by [String] Column to sort by
    # @param direction [String] Sort direction ('ASC' or 'DESC')
    # @param per_page [Integer] Number of records per page
    # @return [ActiveRecord::Result] Result set with columns and rows
    def table_records(table_name, page = 1, order_by = nil, direction = "ASC", per_page = nil, column_filters = nil)
      page = [ 1, page.to_i ].max
      default_per_page = self.class.default_per_page
      column_filters ||= {}
      max_records = self.class.max_records
      per_page = (per_page || default_per_page).to_i

      # Ensure we don't fetch too many records for performance/memory reasons
      per_page = [ per_page, max_records ].min

      model = get_model_for(table_name)
      query = model.all

      # Apply column filters if provided
      if column_filters.present?
        column_filters.each do |column, value|
          next if value.blank?
          next unless column_exists?(table_name, column)

          query = apply_column_filter(query, column, value, table_name)
        end
      end

      # Apply sorting if provided
      if order_by.present? && column_exists?(table_name, order_by)
        direction = %w[ASC DESC].include?(direction.to_s.upcase) ? direction.to_s.upcase : "ASC"
        query = query.order("#{connection.quote_column_name(order_by)} #{direction}")
      end

      # Apply pagination
      records = query.limit(per_page).offset((page - 1) * per_page)

      # Get column names for consistent ordering
      column_names = table_columns(table_name).map { |c| c[:name] }

      # Format results
      @query_executor.to_result_set(records, column_names)
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
      model = get_model_for(table_name)
      query = model.all

      # Apply column filters if provided
      if column_filters.present?
        column_filters.each do |column, value|
          next if value.blank?
          next unless column_exists?(table_name, column)

          query = apply_column_filter(query, column, value, table_name)
        end
      end

      query.count
    end

    # Get the number of columns in a table
    # @param table_name [String] Name of the table
    # @return [Integer] Number of columns
    def column_count(table_name)
      table_columns(table_name).size
    end

    # Get the primary key of a table
    # @param table_name [String] Name of the table
    # @return [String, nil] Primary key column name or nil if not found
    def primary_key(table_name)
      @table_metadata_manager.primary_key(table_name)
    end

    # Check if a column exists in a table
    # @param table_name [String] Name of the table
    # @param column_name [String] Name of the column
    # @return [Boolean] true if column exists, false otherwise
    def column_exists?(table_name, column_name)
      @table_metadata_manager.column_exists?(table_name, column_name)
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
    def query_table(table_name, select: nil, order: nil, limit: nil, offset: nil, where: nil)
      model = get_model_for(table_name)
      query = model.all

      query = query.select(select) if select.present?
      query = query.where(where) if where.present?
      query = query.order(order) if order.present?

      # Get max records from configuration
      max_records = self.class.max_records
      query = query.limit([ limit || max_records, max_records ].min) # Apply safety limit
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

    # Get table indexes
    # @param table_name [String] Name of the table
    # @return [Array<Hash>] List of indexes with details
    def fetch_indexes(table_name)
      @table_metadata_manager.fetch_indexes(table_name)
    end

    # Get foreign keys
    # @param table_name [String] Name of the table
    # @return [Array<Hash>] List of foreign keys with details
    def fetch_foreign_keys(table_name)
      @table_metadata_manager.fetch_foreign_keys(table_name)
    end

    # Clear all caches - useful when schema changes are detected
    def clear_all_caches
      @cache_manager.clear_all
    end

    private

    # Ensure we have a valid database connection
    # @return [ActiveRecord::ConnectionAdapters::AbstractAdapter] The database connection
    def ensure_connection
      return @connection if @connection

      ErrorHandler.with_error_handling("establishing database connection") do
        @connection = ActiveRecord::Base.connection
        @adapter_name = @connection.adapter_name.downcase
        @connection
      end
    end

    # Reset caches if they've been around too long
    def reset_cache_if_needed
      @cache_manager.reset_if_needed
    end

    # Get a dynamic AR model for a table
    # @param table_name [String] Name of the table
    # @return [Class] ActiveRecord model class
    def get_model_for(table_name)
      @dynamic_model_factory.get_model_for(table_name)
    end

    # Helper method to apply column filters to a query
    # @param query [ActiveRecord::Relation] The query to apply filters to
    # @param column [String] The column name to filter on
    # @param value [String] The value to filter by
    # @param table_name [String] The name of the table being queried
    # @return [ActiveRecord::Relation] The filtered query
    def apply_column_filter(query, column, value, table_name)
      column_info = table_columns(table_name).find { |c| c[:name] == column }
      return query unless column_info

      column_type = column_info[:type].to_s
      quoted_column = connection.quote_column_name(column)

      if column_type =~ /datetime|timestamp/
        # For datetime columns, get records from that day
        begin
          parsed_date = Time.parse(value.to_s)
          query = query.where("#{quoted_column} = ?", parsed_date)
        rescue => e
          Rails.logger.debug("[DBViewer] Failed to parse datetime: #{e.message}")
          # If parsing fails, fall back to string comparison
          query = query.where("CAST(#{quoted_column} AS CHAR) LIKE ?", "%#{value}%")
        end
      elsif column_type =~ /^date$/
        # For date columns, get records from that day
        begin
          parsed_date = Date.parse(value.to_s)
          query = query.where("#{quoted_column} = ?", parsed_date)
        rescue => e
          Rails.logger.debug("[DBViewer] Failed to parse date: #{e.message}")
          # If parsing fails, fall back to string comparison
          query = query.where("CAST(#{quoted_column} AS CHAR) LIKE ?", "%#{value}%")
        end
      elsif column_type =~ /^time$/
        # For time columns, match the time portion
        begin
          parsed_time = Time.parse(value.to_s)
          formatted_time = parsed_time.strftime("%H:%M:%S")
          # Different databases handle time extraction differently
          if @adapter_name =~ /mysql/
            query = query.where("TIME(#{quoted_column}) = ?", formatted_time)
          elsif @adapter_name =~ /postgresql/
            query = query.where("CAST(#{quoted_column} AS TIME) = ?", formatted_time)
          else
            # SQLite and others - try basic comparison
            query = query.where("#{quoted_column} = ?", formatted_time)
          end
        rescue => e
          Rails.logger.debug("[DBViewer] Failed to parse time: #{e.message}")
          # If parsing fails, fall back to string comparison
          query = query.where("CAST(#{quoted_column} AS CHAR) LIKE ?", "%#{value}%")
        end
      elsif column_type =~ /char|text|string|uuid|enum/i
        query = query.where("#{quoted_column} LIKE ?", "%#{value}%")
      else
        # For numeric types, try exact match if value looks like a number
        if value =~ /\A[+-]?\d+(\.\d+)?\z/
          query = query.where(column => value)
        else
          # Otherwise, try string comparison for non-string fields
          query = query.where("CAST(#{quoted_column} AS CHAR) LIKE ?", "%#{value}%")
        end
      end

      query
    end
  end
end
