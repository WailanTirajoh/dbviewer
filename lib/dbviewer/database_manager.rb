module Dbviewer
  # DatabaseManager handles all database interactions for the DBViewer engine
  # It provides methods to access database structure and data
  class DatabaseManager
    attr_reader :connection, :adapter_name

    # Default number of records per page if not specified
    DEFAULT_PER_PAGE = 20

    # Max number of records to return in any query for safety
    MAX_RECORDS = 10000

    # Cache for dynamically created AR models
    @@dynamic_models = {}

    # Cache for table column info
    @@table_columns_cache = {}

    # Cache for table metadata
    @@table_metadata_cache = {}

    # Cache expiration time in seconds (5 minutes)
    CACHE_EXPIRY = 300

    # Last cache reset time
    @@cache_last_reset = Time.now

    def initialize
      ensure_connection
      reset_cache_if_needed
    end

    # Returns a sorted list of all tables in the database
    # @return [Array<String>] List of table names
    def tables
      return [] unless connection.respond_to?(:tables)

      begin
        # Get and sort tables, cache is handled at the database adapter level
        connection.tables.sort
      rescue => e
        Rails.logger.error("[DBViewer] Error retrieving tables: #{e.message}")
        []
      end
    end

    # Returns column information for a specific table
    # @param table_name [String] Name of the table
    # @return [Array<Hash>] List of column details with name, type, null, default
    def table_columns(table_name)
      return [] if table_name.blank?

      # Return from cache if available
      return @@table_columns_cache[table_name] if @@table_columns_cache[table_name]

      begin
        columns = connection.columns(table_name).map do |column|
          {
            name: column.name,
            type: column.type,
            null: column.null,
            default: column.default,
            primary: column.name == primary_key(table_name)
          }
        end

        # Cache the result
        @@table_columns_cache[table_name] = columns
        columns
      rescue => e
        Rails.logger.error("[DBViewer] Error retrieving columns for table #{table_name}: #{e.message}")
        []
      end
    end

    # Get detailed metadata about a table (primary keys, indexes, foreign keys)
    # @param table_name [String] Name of the table
    # @return [Hash] Table metadata
    def table_metadata(table_name)
      return {} if table_name.blank?

      # Return from cache if available
      return @@table_metadata_cache[table_name] if @@table_metadata_cache[table_name]

      begin
        metadata = {
          primary_key: primary_key(table_name),
          indexes: fetch_indexes(table_name),
          foreign_keys: fetch_foreign_keys(table_name)
        }

        # Cache the result
        @@table_metadata_cache[table_name] = metadata
        metadata
      rescue => e
        Rails.logger.error("[DBViewer] Error retrieving metadata for table #{table_name}: #{e.message}")
        { primary_key: nil, indexes: [], foreign_keys: [] }
      end
    end

    # Get the total count of records in a table
    # @param table_name [String] Name of the table
    # @return [Integer] Number of records
    def table_count(table_name)
      begin
        model = get_model_for(table_name)
        model.count
      rescue => e
        Rails.logger.error("[DBViewer] Error counting records in table #{table_name}: #{e.message}")
        0
      end
    end

    # Get records from a table with pagination and sorting
    # @param table_name [String] Name of the table
    # @param page [Integer] Page number (1-based)
    # @param order_by [String] Column to sort by
    # @param direction [String] Sort direction ('ASC' or 'DESC')
    # @param per_page [Integer] Number of records per page
    # @return [ActiveRecord::Result] Result set with columns and rows
    def table_records(table_name, page = 1, order_by = nil, direction = "ASC", per_page = nil)
      page = [ 1, page.to_i ].max

      # Use class method if defined, otherwise fall back to constant
      default_per_page = self.class.respond_to?(:default_per_page) ? self.class.default_per_page : DEFAULT_PER_PAGE
      max_records = self.class.respond_to?(:max_records) ? self.class.max_records : MAX_RECORDS

      per_page = (per_page || default_per_page).to_i
      per_page = default_per_page if per_page <= 0

      # Ensure we don't fetch too many records for performance/memory reasons
      per_page = [ per_page, max_records ].min

      model = get_model_for(table_name)
      query = model.all

      # Apply sorting if provided
      if order_by.present? && column_exists?(table_name, order_by)
        direction = %w[ASC DESC].include?(direction.to_s.upcase) ? direction.to_s.upcase : "ASC"
        query = query.order("#{connection.quote_column_name(order_by)} #{direction}")
      end

      # Apply pagination
      records = query.limit(per_page).offset((page - 1) * per_page)

      # Transform the ActiveRecord::Relation to the format expected by the application
      to_result_set(records, table_name)
    end

    # Get the number of records in a table (alias for table_count)
    # @param table_name [String] Name of the table
    # @return [Integer] Number of records
    def record_count(table_name)
      table_count(table_name)
    end

    # Get the number of columns in a table
    # @param table_name [String] Name of the table
    # @return [Integer] Number of columns
    def column_count(table_name)
      begin
        table_columns(table_name).size
      rescue => e
        Rails.logger.error("[DBViewer] Error counting columns in table #{table_name}: #{e.message}")
        0
      end
    end

    # Get the primary key of a table
    # @param table_name [String] Name of the table
    # @return [String, nil] Primary key column name or nil if not found
    def primary_key(table_name)
      begin
        connection.primary_key(table_name)
      rescue => e
        Rails.logger.error("[DBViewer] Error retrieving primary key for table #{table_name}: #{e.message}")
        nil
      end
    end

    # Check if a column exists in a table
    # @param table_name [String] Name of the table
    # @param column_name [String] Name of the column
    # @return [Boolean] true if column exists, false otherwise
    def column_exists?(table_name, column_name)
      return false if table_name.blank? || column_name.blank?

      begin
        columns = table_columns(table_name)
        columns.any? { |col| col[:name].to_s == column_name.to_s }
      rescue => e
        Rails.logger.error("[DBViewer] Error checking column existence for #{column_name} in #{table_name}: #{e.message}")
        false
      end
    end

    # Execute a raw SQL query after validating for safety
    # @param sql [String] SQL query to execute
    # @return [ActiveRecord::Result] Result set with columns and rows
    # @raise [StandardError] If the query is invalid or unsafe
    def execute_query(sql)
      # Use the SqlValidator class to validate and normalize the SQL query
      begin
        # Validate and normalize the SQL
        normalized_sql = ::Dbviewer::SqlValidator.validate!(sql.to_s)

        # Get max records from configuration if available
        max_records = self.class.respond_to?(:max_records) ? self.class.max_records : MAX_RECORDS

        # Add a safety limit if not already present
        unless normalized_sql =~ /\bLIMIT\s+\d+\s*$/i
          normalized_sql = "#{normalized_sql} LIMIT #{max_records}"
        end

        # Log and execute the query
        Rails.logger.info("[DBViewer] Executing SQL query: #{normalized_sql}")
        start_time = Time.now
        result = connection.exec_query(normalized_sql)
        duration = Time.now - start_time

        Rails.logger.info("[DBViewer] Query completed in #{duration.round(2)}s, returned #{result.rows.size} rows")
        result
      rescue => e
        Rails.logger.error("[DBViewer] SQL query error: #{e.message} for query: #{sql}")
        raise e
      end
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
      begin
        model = get_model_for(table_name)
        query = model.all

        query = query.select(select) if select.present?
        query = query.where(where) if where.present?
        query = query.order(order) if order.present?

        # Get max records from configuration if available
        max_records = self.class.respond_to?(:max_records) ? self.class.max_records : MAX_RECORDS
        query = query.limit([ limit || max_records, max_records ].min) # Apply safety limit
        query = query.offset(offset) if offset.present?

        to_result_set(query, table_name)
      rescue => e
        Rails.logger.error("[DBViewer] Error querying table #{table_name}: #{e.message}")
        raise e
      end
    end

    # Get table indexes
    # @param table_name [String] Name of the table
    # @return [Array<Hash>] List of indexes with details
    def fetch_indexes(table_name)
      return [] if table_name.blank?

      begin
        # Only some adapters support index retrieval
        if connection.respond_to?(:indexes)
          connection.indexes(table_name).map do |index|
            {
              name: index.name,
              columns: index.columns,
              unique: index.unique
            }
          end
        else
          []
        end
      rescue => e
        Rails.logger.error("[DBViewer] Error retrieving indexes for table #{table_name}: #{e.message}")
        []
      end
    end

    # Get foreign keys
    # @param table_name [String] Name of the table
    # @return [Array<Hash>] List of foreign keys with details
    def fetch_foreign_keys(table_name)
      return [] if table_name.blank?

      begin
        # Only some adapters support foreign key retrieval
        if connection.respond_to?(:foreign_keys)
          connection.foreign_keys(table_name).map do |fk|
            {
              name: fk.name,
              from_table: fk.from_table,
              to_table: fk.to_table,
              column: fk.column,
              primary_key: fk.primary_key
            }
          end
        else
          []
        end
      rescue => e
        Rails.logger.error("[DBViewer] Error retrieving foreign keys for table #{table_name}: #{e.message}")
        []
      end
    end

    private

    # Ensure we have a valid database connection
    # @return [ActiveRecord::ConnectionAdapters::AbstractAdapter] The database connection
    def ensure_connection
      return @connection if @connection

      begin
        @connection = ActiveRecord::Base.connection
        @adapter_name = @connection.adapter_name.downcase
        @connection
      rescue => e
        Rails.logger.error("[DBViewer] Database connection error: #{e.message}")
        raise e
      end
    end

    # Reset caches if they've been around too long
    def reset_cache_if_needed
      # Get cache expiry from configuration if available
      cache_expiry = self.class.respond_to?(:cache_expiry) ? self.class.cache_expiry : CACHE_EXPIRY

      if Time.now - @@cache_last_reset > cache_expiry
        @@table_columns_cache = {}
        @@table_metadata_cache = {}
        @@cache_last_reset = Time.now
        Rails.logger.info("[DBViewer] Cache reset due to expiry after #{cache_expiry} seconds")
      end
    end

    # Clear all caches - useful when schema changes are detected
    def clear_all_caches
      @@dynamic_models = {}
      @@table_columns_cache = {}
      @@table_metadata_cache = {}
      @@cache_last_reset = Time.now
      Rails.logger.info("[DBViewer] All caches cleared")
    end

    # Dynamically create an ActiveRecord model for a table
    # @param table_name [String] Name of the table
    # @return [Class] ActiveRecord model class for the table
    def get_model_for(table_name)
      return nil if table_name.blank?

      begin
        model_name = table_name.classify

        # Return cached model if available
        return @@dynamic_models[table_name] if @@dynamic_models[table_name]

        # Create a new model class dynamically
        model = Class.new(ActiveRecord::Base) do
          self.table_name = table_name

          # Some tables might not have primary keys, so we handle that
          begin
            primary_key = connection.primary_key(table_name)
            self.primary_key = primary_key if primary_key.present?
          rescue => e
            # If we can't determine the primary key, default to id or set to nil
            self.primary_key = "id"
          end

          # Disable STI
          self.inheritance_column = :_type_disabled

          # Disable timestamps for better compatibility
          self.record_timestamps = false
        end

        # Set model name constant if not already taken
        # Use a namespace to avoid polluting the global namespace
        unless Dbviewer.const_defined?("DynamicModel_#{model_name}")
          Dbviewer.const_set("DynamicModel_#{model_name}", model)
        end

        # Cache the model
        @@dynamic_models[table_name] = model
        model
      rescue => e
        Rails.logger.error("[DBViewer] Error creating model for table #{table_name}: #{e.message}")
        raise e
      end
    end

    # Convert ActiveRecord::Relation to the expected result format
    # @param records [ActiveRecord::Relation] Records to convert
    # @param table_name [String] Name of the table
    # @return [ActiveRecord::Result] Result set with columns and rows
    def to_result_set(records, table_name)
      begin
        column_names = table_columns(table_name).map { |c| c[:name] }

        rows = records.map do |record|
          column_names.map do |col|
            # Handle serialized attributes
            value = record[col]
            serialize_if_needed(value)
          end
        end

        ActiveRecord::Result.new(column_names, rows)
      rescue => e
        Rails.logger.error("[DBViewer] Error converting to result set for table #{table_name}: #{e.message}")
        ActiveRecord::Result.new([], [])
      end
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
