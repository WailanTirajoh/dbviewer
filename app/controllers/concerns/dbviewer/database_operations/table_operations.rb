module Dbviewer
  module DatabaseOperations
    module TableOperations
      extend ActiveSupport::Concern

      # Fetch all tables with their stats
      # By default, don't include record counts for better performance on sidebar
      def fetch_tables(include_record_counts = false)
        database_manager.tables.map do |table_name|
          table_stats = { name: table_name }
          table_stats[:record_count] = fetch_table_record_count(table_name) if include_record_counts
          table_stats
        end
      end

      # Get column information for a specific table
      def fetch_table_columns(table_name)
        database_manager.table_columns(table_name)
      end

      # Fetch records for a table with pagination and sorting
      def fetch_table_records(table_name, query_params)
        database_manager.table_records(table_name, query_params)
      end

      # Get filtered record count for a table
      def fetch_table_record_count(table_name, column_filters = {})
        database_manager.table_record_count(table_name, column_filters)
      end

      # Get table metadata for display (e.g., primary key, foreign keys, indexes)
      def fetch_table_metadata(table_name)
        database_manager.table_metadata(table_name)
      end

      private

      # Check if a table has a created_at column for timestamp visualization
      def has_timestamp_column?(table_name)
        fetch_table_columns(table_name).any? do |column|
          column[:name] == "created_at" && [ :datetime, :timestamp ].include?(column[:type])
        end
      end
    end
  end
end
