module Dbviewer
  module Database
    # Manager handles all database interactions for the DBViewer engine
    # It provides methods to access database structure and data
    class Manager
      attr_reader :connection, :adapter_name, :table_query_operations, :connection_key

      # Initialize the database manager
      # @param connection_key [Symbol] The key identifying the connection in configuration
      def initialize(connection_key = nil)
        @connection_key = connection_key || Dbviewer.configuration.current_connection
        ensure_connection
        @cache_manager = ::Dbviewer::Cache::InMemory.new(configuration.cache_expiry)
        @table_metadata_manager = ::Dbviewer::Database::MetadataManager.new(@connection, @cache_manager)
        @dynamic_model_factory = ::Dbviewer::Database::DynamicModelFactory.new(@connection, @cache_manager, @table_metadata_manager)
        @query_executor = ::Dbviewer::Query::Executor.new(@connection, configuration)
        @table_query_operations = ::Dbviewer::Datatable::QueryOperations.new(
          @connection,
          @dynamic_model_factory,
          @table_metadata_manager
        )
      end

      # Get configuration from class method or Dbviewer
      def configuration
        @configuration ||= Dbviewer.configuration
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
        @table_query_operations.table_count(table_name)
      end

      # Get records from a table with pagination and sorting
      # @param table_name [String] Name of the table
      # @param query_params [Dbviewer::Datatable::QueryParams] Query parameters for pagination and sorting
      # @return [ActiveRecord::Result] Result set with columns and rows
      def table_records(table_name, query_params)
        @table_query_operations.table_records(
          table_name,
          query_params
        )
      end

      # Get the number of records in a table (alias for table_count)
      # @param table_name [String] Name of the table
      # @return [Integer] Number of records
      def record_count(table_name)
        @table_query_operations.record_count(table_name)
      end

      # Get the number of records in a table with filters applied
      # @param table_name [String] Name of the table
      # @param column_filters [Hash] Hash of column_name => filter_value for filtering
      # @return [Integer] Number of filtered records
      def table_record_count(table_name, column_filters = {})
        @table_query_operations.table_record_count(table_name, column_filters)
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

      # Calculate the total size of the database schema
      # @return [Integer, nil] Database size in bytes or nil if unsupported
      def fetch_schema_size
        case adapter_name
        when /mysql/
          fetch_mysql_size
        when /postgres/
          fetch_postgres_size
        when /sqlite/
          fetch_sqlite_size
        else
          nil # Unsupported database type for size calculation
        end
      end

      # Get a dynamic AR model for a table
      # @param table_name [String] Name of the table
      # @return [Class] ActiveRecord model class
      def get_model_for(table_name)
        @dynamic_model_factory.get_model_for(table_name)
      end

      private

      def fetch_mysql_size
        query = "SELECT SUM(data_length + index_length) AS size FROM information_schema.TABLES WHERE table_schema = DATABASE()"
        fetch_size_from_query(query)
      end

      def fetch_postgres_size
        query = "SELECT pg_database_size(current_database()) AS size"
        fetch_size_from_query(query)
      end

      def fetch_sqlite_size
        page_count = fetch_sqlite_pragma_value("page_count")
        page_size = fetch_sqlite_pragma_value("page_size")
        page_count * page_size
      end

      def fetch_sqlite_pragma_value(pragma_name)
        execute_sqlite_pragma(pragma_name).first.values.first.to_i
      end

      def fetch_size_from_query(query)
        result = execute_query(query).first
        result ? result["size"].to_i : nil
      end

      # Ensure we have a valid database connection
      # @return [ActiveRecord::ConnectionAdapters::AbstractAdapter] The database connection
      def ensure_connection
        return @connection if @connection
        connection_config = Dbviewer.configuration.database_connections[@connection_key]

        if connection_config && connection_config[:connection_class]
          begin
            @connection = connection_config[:connection_class].constantize.connection
            @adapter_name = @connection.adapter_name.downcase
          rescue => e
            raise "DBViewer database connection failed: #{e.message}"
          end
        else
          @connection = ActiveRecord::Base.connection
          @adapter_name = @connection.adapter_name.downcase
        end

        @connection
      end
    end
  end
end
