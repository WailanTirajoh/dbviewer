module Dbviewer
  # TableMetadataManager handles retrieving and managing table structure information
  class TableMetadataManager
    # Initialize with a connection and cache manager
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
    # @param cache_manager [Dbviewer::CacheManager] Cache manager instance
    def initialize(connection, cache_manager)
      @connection = connection
      @cache_manager = cache_manager
    end

    # Get all tables in the database
    # @return [Array<String>] List of table names
    def tables
      @connection.tables.sort
    end

    # Get column information for a table
    # @param table_name [String] Name of the table
    # @return [Array<Hash>] List of column details
    def table_columns(table_name)
      cached_columns = @cache_manager.get_columns(table_name)
      return cached_columns if cached_columns

      columns = @connection.columns(table_name).map do |column|
        {
          name: column.name,
          type: column.type,
          null: column.null,
          default: column.default,
          primary: column.name == primary_key(table_name)
        }
      end

      # Cache the result
      @cache_manager.store_columns(table_name, columns)
      columns
    end

    # Get detailed metadata about a table
    # @param table_name [String] Name of the table
    # @return [Hash] Table metadata
    def table_metadata(table_name)
      cached_metadata = @cache_manager.get_metadata(table_name)
      return cached_metadata if cached_metadata

      metadata = {
        primary_key: primary_key(table_name),
        indexes: fetch_indexes(table_name),
        foreign_keys: fetch_foreign_keys(table_name)
      }

      @cache_manager.store_metadata(table_name, metadata)
      metadata
    end

    # Get the primary key of a table
    # @param table_name [String] Name of the table
    # @return [String, nil] Primary key column name or nil if not found
    def primary_key(table_name)
      @connection.primary_key(table_name)
    rescue => e
      Rails.logger.error("[DBViewer] Error retrieving primary key for table #{table_name}: #{e.message}")
      nil
    end

    # Check if a column exists in a table
    # @param table_name [String] Name of the table
    # @param column_name [String] Name of the column
    # @return [Boolean] true if column exists, false otherwise
    def column_exists?(table_name, column_name)
      columns = table_columns(table_name)
      columns.any? { |col| col[:name].to_s == column_name.to_s }
    end

    # Get table indexes
    # @param table_name [String] Name of the table
    # @return [Array<Hash>] List of indexes with details
    def fetch_indexes(table_name)
      @connection.indexes(table_name).map do |index|
        {
          name: index.name,
          columns: index.columns,
          unique: index.unique
        }
      end
    end

    # Get foreign keys
    # @param table_name [String] Name of the table
    # @return [Array<Hash>] List of foreign keys with details
    def fetch_foreign_keys(table_name)
      @connection.foreign_keys(table_name).map do |fk|
        {
          name: fk.name,
          from_table: fk.from_table,
          to_table: fk.to_table,
          column: fk.column,
          primary_key: fk.primary_key
        }
      end
    end
  end
end
