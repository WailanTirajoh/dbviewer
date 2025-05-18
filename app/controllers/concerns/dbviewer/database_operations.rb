module Dbviewer
  module DatabaseOperations
    extend ActiveSupport::Concern

    included do
      helper_method :current_table?, :get_database_name if respond_to?(:helper_method)
    end

    # Initialize the database manager
    def database_manager
      @database_manager ||= ::Dbviewer::DatabaseManager.new
    end

    # Get the name of the current database
    def get_database_name
      adapter = database_manager.connection.adapter_name.downcase

      case adapter
      when /mysql/
        query = "SELECT DATABASE() as db_name"
        result = database_manager.execute_query(query).first
        result ? result["db_name"] : "Database"
      when /postgres/
        query = "SELECT current_database() as db_name"
        result = database_manager.execute_query(query).first
        result ? result["db_name"] : "Database"
      when /sqlite/
        # For SQLite, extract the database name from the connection_config
        database_path = ActiveRecord::Base.connection.pool.spec.config[:database] || ""
        File.basename(database_path, ".*") || "SQLite Database"
      else
        "Database" # Default fallback
      end
    rescue => e
      Rails.logger.error("Error retrieving database name: #{e.message}")
      "Database"
    end

    # Fetch all tables with their stats
    # By default, don't include record counts for better performance on sidebar
    def fetch_tables_with_stats(include_record_counts = false)
      database_manager.tables.map do |table_name|
        table_stats = {
          name: table_name,
          columns_count: database_manager.column_count(table_name)
        }

        # Only fetch record counts if explicitly requested
        table_stats[:record_count] = database_manager.record_count(table_name) if include_record_counts

        table_stats
      end
    end

    # Gather database analytics information
    def fetch_database_analytics
      # For analytics, we do need record counts
      tables = fetch_tables_with_stats(include_record_counts: true)

      # Calculate overall statistics
      analytics = {
        total_tables: tables.size,
        total_records: tables.sum { |t| t[:record_count] },
        total_columns: tables.sum { |t| t[:columns_count] },
        largest_tables: tables.sort_by { |t| -t[:record_count] }.first(5),
        widest_tables: tables.sort_by { |t| -t[:columns_count] }.first(5),
        empty_tables: tables.select { |t| t[:record_count] == 0 }
      }

      # Calculate schema size if possible
      begin
        analytics[:schema_size] = calculate_schema_size
      rescue => e
        Rails.logger.error("Error calculating schema size: #{e.message}")
        analytics[:schema_size] = nil
      end

      # Calculate average rows per table
      if tables.any?
        analytics[:avg_records_per_table] = (analytics[:total_records].to_f / tables.size).round(1)
        analytics[:avg_columns_per_table] = (analytics[:total_columns].to_f / tables.size).round(1)
      else
        analytics[:avg_records_per_table] = 0
        analytics[:avg_columns_per_table] = 0
      end

      analytics
    end

    # Calculate approximate schema size
    def calculate_schema_size
      adapter = database_manager.connection.adapter_name.downcase

      case adapter
      when /mysql/
        query = <<-SQL
          SELECT
            SUM(data_length + index_length) AS size
          FROM
            information_schema.TABLES
          WHERE
            table_schema = DATABASE()
        SQL
        result = database_manager.execute_query(query).first
        result ? result["size"].to_i : nil
      when /postgres/
        query = <<-SQL
          SELECT pg_database_size(current_database()) AS size
        SQL
        result = database_manager.execute_query(query).first
        result ? result["size"].to_i : nil
      when /sqlite/
        # For SQLite, we can use the page count and page size
        query = "PRAGMA page_count"
        page_count = database_manager.execute_query(query).first.values.first.to_i

        query = "PRAGMA page_size"
        page_size = database_manager.execute_query(query).first.values.first.to_i

        page_count * page_size
      else
        nil # Unsupported database type for size calculation
      end
    rescue => e
      Rails.logger.error("Error calculating database size: #{e.message}")
      nil
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

      # Use the raw query parameter, or fall back to default
      @query = params[:query].present? ? params[:query].to_s : default_query

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

    # Export table data to CSV
    def export_table_to_csv(table_name, limit = 10000, include_headers = true)
      require "csv"

      begin
        records = database_manager.table_records(
          table_name,
          1, # First page
          nil, # Default sorting
          "asc",
          limit # Limit number of records
        )

        csv_data = CSV.generate do |csv|
          # Add headers if requested
          csv << records.columns if include_headers

          # Add rows
          records.rows.each do |row|
            csv << row.map { |cell| format_csv_value(cell) }
          end
        end

        csv_data
      rescue => e
        Rails.logger.error("CSV Export error for table #{table_name}: #{e.message}")
        raise "Error exporting to CSV: #{e.message}"
      end
    end

    private

    # Format cell values for CSV export to handle nil values and special characters
    def format_csv_value(value)
      return "" if value.nil?
      value.to_s
    end

    # Check if a table has a created_at column for timestamp visualization
    def has_timestamp_column?(table_name)
      columns = fetch_table_columns(table_name)
      columns.any? { |col| col[:name] == "created_at" && [ :datetime, :timestamp ].include?(col[:type]) }
    end

    # Fetch timestamp data for visualization (hourly, daily, weekly)
    def fetch_timestamp_data(table_name, grouping = "daily")
      return nil unless has_timestamp_column?(table_name)

      quoted_table = safe_quote_table_name(table_name)
      adapter = database_manager.connection.adapter_name.downcase

      sql_query = case grouping
      when "hourly"
        case adapter
        when /mysql/
          "SELECT DATE_FORMAT(created_at, '%Y-%m-%d %H:00:00') as time_group, COUNT(*) as count FROM #{quoted_table} GROUP BY time_group ORDER BY time_group DESC LIMIT 48"
        when /postgres/
          "SELECT date_trunc('hour', created_at) as time_group, COUNT(*) as count FROM #{quoted_table} GROUP BY time_group ORDER BY time_group DESC LIMIT 48"
        else # SQLite and others
          "SELECT strftime('%Y-%m-%d %H:00:00', created_at) as time_group, COUNT(*) as count FROM #{quoted_table} GROUP BY time_group ORDER BY time_group DESC LIMIT 48"
        end
      when "daily"
        case adapter
        when /mysql/
          "SELECT DATE_FORMAT(created_at, '%Y-%m-%d') as time_group, COUNT(*) as count FROM #{quoted_table} GROUP BY time_group ORDER BY time_group DESC LIMIT 30"
        when /postgres/
          "SELECT date_trunc('day', created_at) as time_group, COUNT(*) as count FROM #{quoted_table} GROUP BY time_group ORDER BY time_group DESC LIMIT 30"
        else # SQLite and others
          "SELECT strftime('%Y-%m-%d', created_at) as time_group, COUNT(*) as count FROM #{quoted_table} GROUP BY time_group ORDER BY time_group DESC LIMIT 30"
        end
      when "weekly"
        case adapter
        when /mysql/
          "SELECT DATE_FORMAT(created_at, '%Y-%u') as time_group, YEARWEEK(created_at) as sort_key, COUNT(*) as count FROM #{quoted_table} GROUP BY time_group ORDER BY sort_key DESC LIMIT 26"
        when /postgres/
          "SELECT date_trunc('week', created_at) as time_group, COUNT(*) as count FROM #{quoted_table} GROUP BY time_group ORDER BY time_group DESC LIMIT 26"
        else # SQLite and others
          "SELECT strftime('%Y-%W', created_at) as time_group, COUNT(*) as count FROM #{quoted_table} GROUP BY time_group ORDER BY time_group DESC LIMIT 26"
        end
      else
        return nil
      end

      begin
        result = database_manager.execute_query(sql_query)

        # Format the data for the chart
        result.map do |row|
          time_str = row["time_group"].to_s
          count = row["count"].to_i

          # Format the label based on grouping type
          label = case grouping
          when "hourly"
            # For hourly, show "May 10, 2PM"
            time = time_str.is_a?(Time) ? time_str : Time.parse(time_str)
            time.strftime("%b %d, %l%p")
          when "daily"
            # For daily, show "May 10"
            time = time_str.is_a?(Time) ? time_str : (time_str.include?("-") ? Time.parse(time_str) : Time.now)
            time.strftime("%b %d")
          when "weekly"
            # For weekly, show "Week 19" or the week's start date
            if time_str.include?("-")
              week_num = time_str.split("-").last.to_i
              "Week #{week_num}"
            else
              time = time_str.is_a?(Time) ? time_str : Time.parse(time_str)
              "Week #{time.strftime('%W')}"
            end
          end

          { label: label, value: count, raw_date: time_str }
        end
      rescue => e
        Rails.logger.error("[DBViewer] Error fetching timestamp data: #{e.message}")
        nil
      end
    end
  end
end
