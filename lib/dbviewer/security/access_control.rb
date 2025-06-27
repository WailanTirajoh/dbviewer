module Dbviewer
  module Security
    # Access control service to validate table and column access
    class AccessControl
      def initialize(config = nil)
        @config = config || Dbviewer.configuration
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

        # Extract table names from the SQL query
        extracted_tables = extract_table_names_from_sql(sql)

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

      # Extract table names from SQL query (simplified approach)
      # This is a basic implementation - for production use, consider using a proper SQL parser
      # @param sql [String] The SQL query
      # @return [Array<String>] List of table names found in the query
      def extract_table_names_from_sql(sql)
        # Remove comments and normalize whitespace
        cleaned_sql = sql.gsub(/--.*$/, "").gsub(/\/\*.*?\*\//m, "").squeeze(" ")

        # Simple regex to extract table names after FROM and JOIN clauses
        # This handles both quoted and unquoted table names
        table_names = []

        # Match FROM clause - handles quoted, escaped quoted, and unquoted table names
        # Matches: FROM table_name, FROM "table_name", FROM `table_name`, FROM \"table_name\"
        from_matches = cleaned_sql.scan(/\bFROM\s+(?:\\?"([^"\\]+)\\?"|`([^`]+)`|([a-zA-Z_][a-zA-Z0-9_]*))/i)
        from_matches.each do |match|
          # match is an array where only one element will be non-nil
          table_name = match.compact.first
          table_names << table_name if table_name
        end

        # Match JOIN clauses - handles quoted, escaped quoted, and unquoted table names
        # Matches: JOIN table_name, JOIN "table_name", JOIN `table_name`, JOIN \"table_name\"
        join_matches = cleaned_sql.scan(/\bJOIN\s+(?:\\?"([^"\\]+)\\?"|`([^`]+)`|([a-zA-Z_][a-zA-Z0-9_]*))/i)
        join_matches.each do |match|
          # match is an array where only one element will be non-nil
          table_name = match.compact.first
          table_names << table_name if table_name
        end

        # Remove duplicates and return (preserve original case for table names)
        table_names.uniq
      end
    end
  end
end
