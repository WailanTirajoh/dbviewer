module Dbviewer
  module Database
    # MetadataManager handles retrieving and managing table structure information
    class MetadataManager
      # Initialize with a connection and cache manager
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param cache_manager [Dbviewer::Database::CacheManager] Cache manager instance
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
        # Cache columns for longer since schema changes are infrequent
        @cache_manager.fetch("columns-#{table_name}", expires_in: 600) do
          @connection.columns(table_name).map do |column|
            {
              name: column.name,
              type: column.type,
              null: column.null,
              default: column.default,
              primary: column.name == primary_key(table_name)
            }
          end
        end
      end

      # Get detailed metadata about a table
      # @param table_name [String] Name of the table
      # @return [Hash] Table metadata
      def table_metadata(table_name)
        # Cache metadata for longer since schema relationships change infrequently
        @cache_manager.fetch("metadata-#{table_name}", expires_in: 600) do
          {
            primary_key: primary_key(table_name),
            indexes: fetch_indexes(table_name),
            foreign_keys: fetch_foreign_keys(table_name),
            reverse_foreign_keys: fetch_reverse_foreign_keys(table_name)
          }
        end
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

      # Get reverse foreign keys (tables that reference this table)
      # @param table_name [String] Name of the table
      # @return [Array<Hash>] List of reverse foreign keys with details
      def fetch_reverse_foreign_keys(table_name)
        tables
          .reject { |other_table| other_table == table_name }
          .flat_map do |other_table|
            @connection.foreign_keys(other_table)
              .select { |fk| fk.to_table == table_name }
              .map do |fk|
                {
                  name: fk.name,
                  from_table: fk.from_table,
                  to_table: fk.to_table,
                  column: fk.column,
                  primary_key: fk.primary_key,
                  relationship_type: "has_many"
                }
              end
          end
      end
    end
  end
end
