module Dbviewer
  module DatabaseOperations
    extend ActiveSupport::Concern

    included do
      helper_method :current_table? if respond_to?(:helper_method)
    end

    # Initialize the database manager
    def database_manager
      @database_manager ||= ::Dbviewer::DatabaseManager.new
    end

    # Fetch all tables with their record and column counts
    def fetch_tables_with_stats
      database_manager.tables.map do |table_name|
        {
          name: table_name,
          record_count: database_manager.record_count(table_name),
          columns_count: database_manager.column_count(table_name)
        }
      end
    end

    # Get column information for a specific table
    def fetch_table_columns(table_name)
      database_manager.table_columns(table_name)
    end

    # Get the total number of records in a table
    def fetch_table_record_count(table_name)
      database_manager.table_count(table_name)
    end

    # Fetch records for a table with pagination and sorting
    def fetch_table_records(table_name)
      database_manager.table_records(
        table_name,
        @current_page,
        @order_by,
        @order_direction,
        @per_page
      )
    end

    # Safely quote a table name, with fallback
    def safe_quote_table_name(table_name)
      database_manager.connection.quote_table_name(table_name)
    rescue => e
      Rails.logger.warn("Failed to quote table name: #{e.message}")
      table_name
    end

    # Get table metadata for display (e.g., primary key, foreign keys, indexes)
    def fetch_table_metadata(table_name)
      return {} unless database_manager.respond_to?(:table_metadata)

      begin
        database_manager.table_metadata(table_name)
      rescue => e
        Rails.logger.warn("Failed to fetch table metadata: #{e.message}")
        {}
      end
    end

    # Fetch relationships between tables for ERD visualization
    def fetch_table_relationships
      relationships = []

      @tables.each do |table|
        table_name = table[:name]

        # Get foreign keys defined in this table pointing to others
        begin
          metadata = database_manager.table_metadata(table_name)
          if metadata && metadata[:foreign_keys].present?
            metadata[:foreign_keys].each do |fk|
              relationships << {
                from_table: table_name,
                to_table: fk[:to_table],
                from_column: fk[:column],
                to_column: fk[:primary_key],
                name: fk[:name]
              }
            end
          end
        rescue => e
          Rails.logger.error("Error fetching relationships for #{table_name}: #{e.message}")
        end
      end

      relationships
    end

    # Prepare the SQL query - either from params or default
    def prepare_query
      quoted_table = safe_quote_table_name(@table_name)
      default_query = "SELECT * FROM #{quoted_table} LIMIT 100"

      @query = params[:query].presence || default_query

      # Validate query for security
      unless ::Dbviewer::SqlValidator.safe_query?(@query)
        @query = default_query
        flash.now[:warning] = "Only SELECT queries are allowed. Your query contained potentially unsafe operations. Using default query instead."
      end
    end

    # Execute the prepared SQL query
    def execute_query
      begin
        @records = database_manager.execute_query(@query)
        @error = nil
      rescue => e
        @records = nil
        @error = e.message
        Rails.logger.error("SQL Query Error: #{e.message} for query: #{@query}")
      end
    end

    # Helper to check if this is the current table in the UI
    def current_table?(table_name)
      params[:id] == table_name
    end
  end
end
