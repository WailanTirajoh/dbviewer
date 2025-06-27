module Dbviewer
  module Security
    # Access control service to validate table and column access
    class AccessControl
      def initialize(config = nil)
        @config = config || Dbviewer.configuration
        @sql_parser = SqlParser.new
      end

      # Check if a table is accessible based on current access control mode
      # @param table_name [String] Name of the table to check
      # @return [Boolean] true if table is accessible, false otherwise
      def table_accessible?(table_name)
        return true if @config.access_control_mode == :none

        case @config.access_control_mode
        when :whitelist
          @config.allowed_tables.include?(table_name.to_s)
        when :blacklist
          !@config.blocked_tables.include?(table_name.to_s)
        else
          true
        end
      end

      # Get list of accessible tables based on access control settings
      # @param all_tables [Array<String>] List of all available tables
      # @return [Array<String>] Filtered list of accessible tables
      def filter_accessible_tables(all_tables)
        return all_tables if @config.access_control_mode == :none

        all_tables.select { |table| table_accessible?(table) }
      end

      # Get list of accessible columns for a table
      # @param table_name [String] Name of the table
      # @param all_columns [Array<String>] List of all columns in the table
      # @return [Array<String>] Filtered list of accessible columns
      def filter_accessible_columns(table_name, all_columns)
        blocked_columns = @config.blocked_columns[table_name.to_s] || []
        all_columns.reject { |column| blocked_columns.include?(column.to_s) }
      end

      # Validate if a SQL query only accesses allowed tables
      # @param sql [String] The SQL query to validate
      # @return [Boolean] true if query only accesses allowed tables
      def validate_query_table_access(sql)
        return true if @config.access_control_mode == :none

        # Extract table names from the SQL query using the SQL parser
        extracted_tables = @sql_parser.extract_table_names(sql)

        # Check if all extracted tables are accessible
        extracted_tables.all? { |table| table_accessible?(table) }
      end

      # Get access control violation message
      # @param table_name [String] Name of the table that was blocked
      # @return [String] Error message explaining the access violation
      def access_violation_message(table_name = nil)
        case @config.access_control_mode
        when :whitelist
          if table_name
            "Access denied: Table '#{table_name}' is not in the allowed tables list"
          else
            "Access denied: Only the following tables are accessible: #{@config.allowed_tables.join(', ')}"
          end
        when :blacklist
          if table_name
            "Access denied: Table '#{table_name}' is blocked from access"
          else
            "Access denied: The following tables are blocked: #{@config.blocked_tables.join(', ')}"
          end
        else
          "Access denied: Table access is restricted"
        end
      end

      private

      # For backwards compatibility, we keep this method but delegate to SqlParser
      # @deprecated Use SqlParser.extract_table_names directly
      def extract_table_names_from_sql(sql)
        @sql_parser.extract_table_names(sql)
      end
    end
  end
end
