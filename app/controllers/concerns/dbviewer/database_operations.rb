require "csv"

module Dbviewer
  module DatabaseOperations
    extend ActiveSupport::Concern

    included do
      helper_method :current_table?, :get_database_name, :get_adapter_name,
                    :current_connection_key, :available_connections if respond_to?(:helper_method)
    end

    # Get the current active connection key
    def current_connection_key
      # Get the connection key from the session or fall back to the default
      key = session[:dbviewer_connection] || Dbviewer.configuration.current_connection

      # Ensure the key actually exists in our configured connections
      if key && Dbviewer.configuration.database_connections.key?(key.to_sym)
        return key.to_sym
      end

      # If the key doesn't exist, fall back to any available connection
      first_key = Dbviewer.configuration.database_connections.keys.first
      if first_key
        session[:dbviewer_connection] = first_key # Update the session
        return first_key
      end

      # If there are no connections configured, use a default key
      # This should never happen in normal operation, but it's a safety measure
      :default
    end

    # Set the current connection to use
    def switch_connection(connection_key)
      connection_key = connection_key.to_sym if connection_key.respond_to?(:to_sym)

      if connection_key && Dbviewer.configuration.database_connections.key?(connection_key)
        session[:dbviewer_connection] = connection_key
        # Clear the database manager to force it to be recreated with the new connection
        @database_manager = nil
        return true
      else
        # If the connection key doesn't exist, reset to default connection
        if Dbviewer.configuration.database_connections.key?(Dbviewer.configuration.current_connection)
          session[:dbviewer_connection] = Dbviewer.configuration.current_connection
          @database_manager = nil
          return true
        else
          # If even the default connection isn't valid, try the first available connection
          first_key = Dbviewer.configuration.database_connections.keys.first
          if first_key
            session[:dbviewer_connection] = first_key
            @database_manager = nil
            return true
          end
        end
      end

      false # Return false if we couldn't set a valid connection
    end

    # Get list of available connections
    def available_connections
      connections = Dbviewer.configuration.database_connections.map do |key, config|
        # Try to determine the adapter name if it's not already stored
        adapter_name = nil
        if config[:adapter_name].present?
          adapter_name = config[:adapter_name]
        elsif config[:connection].present?
          begin
            adapter_name = config[:connection].connection.adapter_name
          rescue => e
            Rails.logger.error("Error getting adapter name: #{e.message}")
          end
        end

        {
          key: key,
          name: config[:name] || key.to_s.humanize,
          adapter_name: adapter_name,
          current: key.to_sym == current_connection_key.to_sym
        }
      end

      # Ensure at least one connection is marked as current
      unless connections.any? { |c| c[:current] }
        # If no connection is current, mark the first one as current
        if connections.any?
          connections.first[:current] = true
          # Also update the session
          session[:dbviewer_connection] = connections.first[:key]
        end
      end

      connections
    end

    # Initialize the database manager with the current connection
    def database_manager
      @database_manager = ::Dbviewer::Database::Manager.new(current_connection_key)
    end

    # Initialize the table query operations manager
    # This gives direct access to table query operations when needed
    def table_query_operations
      @table_query_operations ||= database_manager.table_query_operations
    end

    # Get the name of the current database
    def get_database_name
      # First check if this connection has a name in the configuration
      current_conn_config = Dbviewer.configuration.database_connections[current_connection_key]
      if current_conn_config && current_conn_config[:name].present?
        return current_conn_config[:name]
      end

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
        database_path = database_manager.connection.pool.spec.config[:database] || ""
        File.basename(database_path, ".*") || "SQLite Database"
      else
        "Database" # Default fallback
      end
    rescue => e
      Rails.logger.error("Error retrieving database name: #{e.message}")
      "Database"
    end

    # Get the name of the current database adapter
    def get_adapter_name
      adapter_name = database_manager.connection.adapter_name.downcase
      adapter_mappings = {
        /mysql/i => "MySQL",
        /postgres/i => "PostgreSQL",
        /sqlite/i => "SQLite",
        /oracle/i => "Oracle",
        /sqlserver|mssql/i => "SQL Server"
      }
      adapter_mappings.find { |pattern, _| adapter_name =~ pattern }&.last || adapter_name.titleize
    rescue => e
      Rails.logger.error("Error retrieving adapter name: #{e.message}")
      "Unknown"
    end

    # Fetch all tables with their stats
    # By default, don't include record counts for better performance on sidebar
    def fetch_tables(include_record_counts = false)
      database_manager.tables.map do |table_name|
        table_stats = {
          name: table_name
        }

        # Only fetch record count if specifically requested
        if include_record_counts
          begin
            table_stats[:record_count] = database_manager.record_count(table_name)
          rescue => e
            Rails.logger.error("Error fetching record count for #{table_name}: #{e.message}")
            table_stats[:record_count] = 0
          end
        end

        table_stats
      end
    rescue => e
      Rails.logger.error("Error fetching tables: #{e.message}")
      []
    end

    # Gather database analytics information
    def fetch_database_analytics
      # For analytics, we do need record counts
      tables = fetch_tables(include_record_counts: true)

      # Calculate overall statistics
      analytics = {
        total_tables: tables.size,
        total_records: tables.sum { |t| t[:record_count] },
        largest_tables: tables.sort_by { |t| -t[:record_count] }.first(10),
        empty_tables: tables.select { |t| t[:record_count] == 0 }
      }
      # Calculate schema size if possible
      analytics[:schema_size] = calculate_schema_size

      analytics
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
    def fetch_table_records(table_name, query_params)
      database_manager.table_records(table_name, query_params)
    end

    # Get filtered record count for a table
    def fetch_filtered_record_count(table_name, column_filters)
      database_manager.filtered_record_count(table_name, column_filters)
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
      # Use functional approach: flat_map to extract all relationships from all tables
      @tables.flat_map do |table|
        extract_table_relationships_from_metadata(table[:name])
      end
    end

    private

    # Extract relationships for a single table from its metadata
    # @param table_name [String] The name of the table to process
    # @return [Array<Hash>] Array of relationship hashes for this table
    def extract_table_relationships_from_metadata(table_name)
      metadata = database_manager.table_metadata(table_name)
      return [] unless metadata&.dig(:foreign_keys)&.present?

      metadata[:foreign_keys].map do |fk|
        {
          from_table: table_name,
          to_table: fk[:to_table],
          from_column: fk[:column],
          to_column: fk[:primary_key],
          name: fk[:name]
        }
      end
    rescue => e
      Rails.logger.error("Error fetching relationships for #{table_name}: #{e.message}")
      [] # Return empty array to continue processing other tables
    end

    # Get mini ERD data for a specific table and its relationships
    def fetch_mini_erd_for_table(table_name)
      related_tables = []
      relationships = []

      # Validate the table exists
      unless database_manager.tables.include?(table_name)
        Rails.logger.error("[DBViewer] Table not found for mini ERD: #{table_name}")
        return {
          tables: [],
          relationships: [],
          error: "Table '#{table_name}' not found in the database"
        }
      end

      # Add current table
      related_tables << { name: table_name }

      Rails.logger.info("[DBViewer] Generating mini ERD for table: #{table_name}")

      # Get foreign keys from this table to others (outgoing relationships)
      begin
        metadata = fetch_table_metadata(table_name)
        Rails.logger.debug("[DBViewer] Table metadata: #{metadata.inspect}")

        if metadata && metadata[:foreign_keys].present?
          metadata[:foreign_keys].each do |fk|
            # Ensure all required fields are present
            next unless fk[:to_table].present? && fk[:column].present?

            # Sanitize table and column names for display
            from_table = table_name.to_s
            to_table = fk[:to_table].to_s
            from_column = fk[:column].to_s
            to_column = fk[:primary_key].to_s.presence || "id"
            relationship_name = fk[:name].to_s.presence || "#{from_table}_to_#{to_table}"

            relationship = {
              from_table: from_table,
              to_table: to_table,
              from_column: from_column,
              to_column: to_column,
              name: relationship_name,
              direction: "outgoing"
            }

            relationships << relationship
            Rails.logger.debug("[DBViewer] Added outgoing relationship: #{relationship.inspect}")

            # Add the related table if not already included
            unless related_tables.any? { |t| t[:name] == to_table }
              related_tables << { name: to_table }
            end
          end
        end
      rescue => e
        Rails.logger.error("[DBViewer] Error fetching outgoing relationships for #{table_name}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end

      # Get foreign keys from other tables to this one (incoming relationships)
      begin
        database_manager.tables.each do |other_table_name|
          next if other_table_name == table_name # Skip self

          begin
            other_metadata = fetch_table_metadata(other_table_name)
            if other_metadata && other_metadata[:foreign_keys].present?
              other_metadata[:foreign_keys].each do |fk|
                if fk[:to_table] == table_name
                  # Ensure all required fields are present
                  next unless fk[:column].present?

                  # Sanitize table and column names for display
                  from_table = other_table_name.to_s
                  to_table = table_name.to_s
                  from_column = fk[:column].to_s
                  to_column = fk[:primary_key].to_s.presence || "id"
                  relationship_name = fk[:name].to_s.presence || "#{from_table}_to_#{to_table}"

                  relationship = {
                    from_table: from_table,
                    to_table: to_table,
                    from_column: from_column,
                    to_column: to_column,
                    name: relationship_name,
                    direction: "incoming"
                  }

                  relationships << relationship
                  Rails.logger.debug("[DBViewer] Added incoming relationship: #{relationship.inspect}")

                  # Add the related table if not already included
                  unless related_tables.any? { |t| t[:name] == from_table }
                    related_tables << { name: from_table }
                  end
                end
              end
            end
          rescue => e
            Rails.logger.error("[DBViewer] Error processing relationships for table #{other_table_name}: #{e.message}")
            # Continue to the next table
          end
        end
      rescue => e
        Rails.logger.error("[DBViewer] Error fetching incoming relationships for #{table_name}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end

      # If no relationships were found, make sure to still include at least the current table
      if relationships.empty?
        Rails.logger.info("[DBViewer] No relationships found for table: #{table_name}")
      end

      result = {
        tables: related_tables,
        relationships: relationships,
        timestamp: Time.now.to_i
      }

      Rails.logger.info("[DBViewer] Mini ERD data generated: #{related_tables.length} tables, #{relationships.length} relationships")
      result
    end

    # Prepare the SQL query - either from params or default
    def prepare_query
      quoted_table = safe_quote_table_name(@table_name)
      default_query = "SELECT * FROM #{quoted_table} LIMIT 100"

      # Use the raw query parameter, or fall back to default
      @query = params[:query].present? ? params[:query].to_s : default_query

      # Validate query for security
      unless ::Dbviewer::Validator::Sql.safe_query?(@query)
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
    def export_table_to_csv(table_name, query_params = nil, include_headers = true)
      records = database_manager.table_query_operations.table_records(table_name, query_params)

      csv_data = CSV.generate do |csv|
        # Add headers if requested
        csv << records.columns if include_headers

        # Add rows
        records.rows.each do |row|
          csv << row.map { |cell| format_csv_value(cell) }
        end
      end

      csv_data
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
