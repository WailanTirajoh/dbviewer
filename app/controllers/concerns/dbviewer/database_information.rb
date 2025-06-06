module Dbviewer
  module DatabaseInformation
    extend ActiveSupport::Concern

    included do
      helper_method :get_database_name, :get_adapter_name if respond_to?(:helper_method)
    end

    # Get the name of the current database
    def get_database_name
      # First check if this connection has a name in the configuration
      current_conn_config = Dbviewer.configuration.database_connections[current_connection_key]
      return current_conn_config[:name] if current_conn_config && current_conn_config[:name].present?

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
    rescue
      "Unknown"
    end

    # Gather database analytics information
    def fetch_database_analytics
      tables = fetch_tables(include_record_counts: true)

      {
        total_tables: tables.size,
        total_records: tables.sum { |t| t[:record_count] },
        largest_tables: tables.sort_by { |t| -t[:record_count] }.first(10),
        empty_tables: tables.select { |t| t[:record_count] == 0 }
      }
    end
  end
end
