module Dbviewer
  module Security
    # SQL parser for extracting table names from SQL queries
    # Handles complex SQL including CTEs, subqueries, joins, and DML operations
    class SqlParser
      require "set"

      # Parse SQL query and extract all table names
      # @param sql [String] The SQL query to parse
      # @return [Array<String>] List of table names found in the query
      def self.extract_table_names(sql)
        new.extract_table_names(sql)
      end

      # Parse SQL query and extract all table names
      # @param sql [String] The SQL query to parse
      # @return [Array<String>] List of table names found in the query
      def extract_table_names(sql)
        return [] if sql.nil? || sql.strip.empty?

        # Remove comments and normalize whitespace
        cleaned_sql = clean_sql(sql)

        # Use a more sophisticated approach to handle complex queries
        table_names = Set.new

        # Split by semicolons to handle multiple statements
        statements = cleaned_sql.split(";").map(&:strip).reject(&:empty?)

        statements.each do |statement|
          table_names.merge(extract_tables_from_statement(statement))
        end

        table_names.to_a.compact
      end

      private

      # Clean SQL by removing comments and normalizing whitespace
      # Properly handles string literals to avoid removing content inside strings
      # @param sql [String] The SQL query to clean
      # @return [String] Cleaned SQL
      def clean_sql(sql)
        result = []
        i = 0
        in_single_quote = false
        in_double_quote = false
        in_single_line_comment = false
        in_multi_line_comment = false

        while i < sql.length
          char = sql[i]
          next_char = i + 1 < sql.length ? sql[i + 1] : nil

          # Handle string literals first (highest priority)
          if !in_single_line_comment && !in_multi_line_comment
            case char
            when "'"
              if !in_double_quote
                # Handle escaped single quotes
                if in_single_quote && next_char == "'"
                  result << char << next_char
                  i += 2
                  next
                else
                  in_single_quote = !in_single_quote
                  result << char
                end
              else
                result << char
              end
            when '"'
              if !in_single_quote
                # Handle escaped double quotes
                if in_double_quote && next_char == '"'
                  result << char << next_char
                  i += 2
                  next
                else
                  in_double_quote = !in_double_quote
                  result << char
                end
              else
                result << char
              end
            when "-"
              # Check for single-line comment start
              if !in_single_quote && !in_double_quote && next_char == "-"
                in_single_line_comment = true
                i += 2
                next
              else
                result << char
              end
            when "/"
              # Check for multi-line comment start
              if !in_single_quote && !in_double_quote && next_char == "*"
                in_multi_line_comment = true
                i += 2
                next
              else
                result << char
              end
            when "*"
              # Check for multi-line comment end
              if in_multi_line_comment && next_char == "/"
                in_multi_line_comment = false
                i += 2
                next
              elsif !in_single_line_comment && !in_multi_line_comment
                result << char
              end
            when "\n", "\r"
              # End single-line comment
              if in_single_line_comment
                in_single_line_comment = false
                result << char
              elsif !in_multi_line_comment
                result << char
              end
            else
              # Regular character
              if !in_single_line_comment && !in_multi_line_comment
                result << char
              end
            end
          else
            # Inside comment - handle comment end conditions
            case char
            when "*"
              if in_multi_line_comment && next_char == "/"
                in_multi_line_comment = false
                i += 2
                next
              end
            when "\n", "\r"
              if in_single_line_comment
                in_single_line_comment = false
                result << char
              end
            end
          end

          i += 1
        end

        # Normalize whitespace and strip
        result.join.squeeze(" ").strip
      end

      # Extract table names from a single SQL statement
      # @param sql [String] A single SQL statement
      # @param cte_names [Set] Set of CTE names to exclude (for recursive calls)
      # @return [Array<String>] List of table names
      def extract_tables_from_statement(sql, cte_names = Set.new)
        table_names = Set.new

        # Handle CTEs (WITH clauses) first and collect CTE names
        cte_data = extract_cte_tables_and_names(sql)
        table_names.merge(cte_data[:table_names])
        current_cte_names = cte_names + cte_data[:cte_names]

        # Handle main query tables
        table_names.merge(extract_main_query_tables(sql, current_cte_names))

        # Handle subqueries recursively
        table_names.merge(extract_subquery_tables(sql, current_cte_names))

        # Remove CTE names from the final result since they're not actual database tables
        (table_names - current_cte_names).to_a
      end

      # Extract table names from CTEs (WITH clauses) and return both actual tables and CTE names
      # @param sql [String] SQL statement
      # @return [Hash] Hash with :table_names and :cte_names arrays
      def extract_cte_tables_and_names(sql)
        table_names = Set.new
        cte_names = Set.new

        # Find all CTE names first using a simpler approach
        # Look for pattern: cte_name AS (
        cte_name_pattern = /\b(\w+)\s+AS\s*\(/i

        sql.scan(cte_name_pattern) do |match|
          cte_name = match[0]
          cte_names.add(cte_name)
        end

        # Then extract table names from the CTE definitions
        # Match WITH clauses (including RECURSIVE)
        cte_pattern = /\bWITH\s+(?:RECURSIVE\s+)?(.+?)(?=\s+SELECT\s+[^(]|\s+INSERT\s+|\s+UPDATE\s+|\s+DELETE\s+)/mi

        cte_match = sql.match(cte_pattern)
        if cte_match
          cte_definitions = cte_match[1]

          # Find all subqueries within the CTE definitions and extract tables from them
          depth = 0
          start_pos = nil
          i = 0

          while i < cte_definitions.length
            char = cte_definitions[i]

            if char == "(" && cte_definitions[i..-1] =~ /^\(\s*SELECT/i
              if depth == 0
                start_pos = i + 1
              end
              depth += 1
            elsif char == ")" && depth > 0
              depth -= 1
              if depth == 0 && start_pos
                subquery = cte_definitions[start_pos...i]
                # Recursively extract tables from the CTE subquery
                table_names.merge(extract_tables_from_statement(subquery, cte_names))
                start_pos = nil
              end
            end

            i += 1
          end
        end

        {
          table_names: table_names.to_a,
          cte_names: cte_names.to_a
        }
      end

      # Extract table names from main query operations
      # @param sql [String] SQL statement
      # @param cte_names [Set] Set of CTE names to exclude
      # @return [Array<String>] List of table names
      def extract_main_query_tables(sql, cte_names = Set.new)
        table_names = Set.new

        # FROM clauses (including table-valued functions and subqueries)
        table_names.merge(extract_from_tables(sql, cte_names))

        # JOIN clauses
        table_names.merge(extract_join_tables(sql, cte_names))

        # INSERT INTO
        table_names.merge(extract_insert_tables(sql, cte_names))

        # UPDATE (including UPDATE ... FROM)
        table_names.merge(extract_update_tables(sql, cte_names))

        # DELETE FROM (including DELETE ... FROM ... JOIN)
        table_names.merge(extract_delete_tables(sql, cte_names))

        # UNION, INTERSECT, EXCEPT
        table_names.merge(extract_set_operation_tables(sql, cte_names))

        table_names.to_a
      end

      # Extract table names from FROM clauses
      # @param sql [String] SQL statement
      # @param cte_names [Set] Set of CTE names to exclude
      # @return [Array<String>] List of table names
      def extract_from_tables(sql, cte_names = Set.new)
        table_names = Set.new

        # Match FROM clause with various patterns
        # Handle: FROM table, FROM schema.table, FROM "table", FROM (subquery), FROM function()
        from_pattern = /\bFROM\s+(?![\(\s]*SELECT)((?:\w+\.)?(?:\\?"[^"\\]+\\?"|`[^`]+`|\w+)(?:\s*\([^)]*\))?)/i

        sql.scan(from_pattern) do |match|
          table_ref = match[0]
          # Skip if it looks like a function call or subquery
          unless table_ref.include?("(") && table_ref.include?(")")
            table_name = extract_table_name_from_reference(table_ref)
            # Only add if it's not a CTE name
            table_names.add(table_name) if table_name && !cte_names.include?(table_name)
          end
        end

        table_names.to_a
      end

      # Extract table names from JOIN clauses
      # @param sql [String] SQL statement
      # @param cte_names [Set] Set of CTE names to exclude
      # @return [Array<String>] List of table names
      def extract_join_tables(sql, cte_names = Set.new)
        table_names = Set.new

        # Match all types of JOINs
        join_pattern = /\b(?:INNER\s+|LEFT\s+(?:OUTER\s+)?|RIGHT\s+(?:OUTER\s+)?|FULL\s+(?:OUTER\s+)?|CROSS\s+)?JOIN\s+(?![\(\s]*SELECT)((?:\w+\.)?(?:\\?"[^"\\]+\\?"|`[^`]+`|\w+))/i

        sql.scan(join_pattern) do |match|
          table_ref = match[0]
          table_name = extract_table_name_from_reference(table_ref)
          # Only add if it's not a CTE name
          table_names.add(table_name) if table_name && !cte_names.include?(table_name)
        end

        table_names.to_a
      end

      # Extract table names from INSERT statements
      # @param sql [String] SQL statement
      # @param cte_names [Set] Set of CTE names to exclude
      # @return [Array<String>] List of table names
      def extract_insert_tables(sql, cte_names = Set.new)
        table_names = Set.new

        # INSERT INTO table
        insert_pattern = /\bINSERT\s+INTO\s+((?:\w+\.)?(?:\\?"[^"\\]+\\?"|`[^`]+`|\w+))/i

        sql.scan(insert_pattern) do |match|
          table_ref = match[0]
          table_name = extract_table_name_from_reference(table_ref)
          # Only add if it's not a CTE name
          table_names.add(table_name) if table_name && !cte_names.include?(table_name)
        end

        table_names.to_a
      end

      # Extract table names from UPDATE statements
      # @param sql [String] SQL statement
      # @param cte_names [Set] Set of CTE names to exclude
      # @return [Array<String>] List of table names
      def extract_update_tables(sql, cte_names = Set.new)
        table_names = Set.new

        # UPDATE table SET ... or UPDATE table ... FROM other_table
        update_pattern = /\bUPDATE\s+((?:\w+\.)?(?:\\?"[^"\\]+\\?"|`[^`]+`|\w+))/i

        sql.scan(update_pattern) do |match|
          table_ref = match[0]
          table_name = extract_table_name_from_reference(table_ref)
          # Only add if it's not a CTE name
          table_names.add(table_name) if table_name && !cte_names.include?(table_name)
        end

        # UPDATE ... FROM (PostgreSQL style)
        update_from_pattern = /\bUPDATE\s+\w+.*?\bFROM\s+((?:\w+\.)?(?:\\?"[^"\\]+\\?"|`[^`]+`|\w+))/i

        sql.scan(update_from_pattern) do |match|
          table_ref = match[0]
          table_name = extract_table_name_from_reference(table_ref)
          # Only add if it's not a CTE name
          table_names.add(table_name) if table_name && !cte_names.include?(table_name)
        end

        table_names.to_a
      end

      # Extract table names from DELETE statements
      # @param sql [String] SQL statement
      # @param cte_names [Set] Set of CTE names to exclude
      # @return [Array<String>] List of table names
      def extract_delete_tables(sql, cte_names = Set.new)
        table_names = Set.new

        # DELETE FROM table
        delete_pattern = /\bDELETE\s+FROM\s+((?:\w+\.)?(?:\\?"[^"\\]+\\?"|`[^`]+`|\w+))/i

        sql.scan(delete_pattern) do |match|
          table_ref = match[0]
          table_name = extract_table_name_from_reference(table_ref)
          # Only add if it's not a CTE name
          table_names.add(table_name) if table_name && !cte_names.include?(table_name)
        end

        table_names.to_a
      end

      # Extract table names from set operations (UNION, INTERSECT, EXCEPT)
      # @param sql [String] SQL statement
      # @param cte_names [Set] Set of CTE names to exclude
      # @return [Array<String>] List of table names
      def extract_set_operation_tables(sql, cte_names = Set.new)
        table_names = Set.new

        # Split by set operations and process each part
        parts = sql.split(/\b(?:UNION(?:\s+ALL)?|INTERSECT|EXCEPT)\b/i)

        parts.each do |part|
          table_names.merge(extract_from_tables(part, cte_names))
          table_names.merge(extract_join_tables(part, cte_names))
        end

        table_names.to_a
      end

      # Extract table names from subqueries
      # @param sql [String] SQL statement
      # @param cte_names [Set] Set of CTE names to exclude
      # @return [Array<String>] List of table names
      def extract_subquery_tables(sql, cte_names = Set.new)
        table_names = Set.new

        # Find subqueries in parentheses
        # This is a simplified approach - nested parentheses are complex to handle with regex

        # Track parentheses depth to handle nested subqueries
        depth = 0
        start_pos = nil
        i = 0

        while i < sql.length
          char = sql[i]

          if char == "(" && sql[i..-1] =~ /^\(\s*SELECT/i
            if depth == 0
              start_pos = i + 1
            end
            depth += 1
          elsif char == ")" && depth > 0
            depth -= 1
            if depth == 0 && start_pos
              subquery = sql[start_pos...i]
              # Recursively process subquery
              table_names.merge(extract_tables_from_statement(subquery, cte_names))
              start_pos = nil
            end
          end

          i += 1
        end

        table_names.to_a
      end

      # Extract clean table name from a table reference
      # @param table_ref [String] Table reference (e.g., "schema.table", "table", "\"table\"")
      # @return [String, nil] Clean table name or nil if invalid
      def extract_table_name_from_reference(table_ref)
        return nil if table_ref.nil? || table_ref.strip.empty?

        # Remove schema prefix (schema.table -> table)
        if table_ref.include?(".")
          parts = table_ref.split(".")
          table_part = parts.last
        else
          table_part = table_ref
        end

        # Remove quotes and clean up
        table_name = table_part.gsub(/^\\?"([^"\\]+)\\?"$/, '\1')  # Remove escaped quotes
                              .gsub(/^"([^"]+)"$/, '\1')          # Remove double quotes
                              .gsub(/^`([^`]+)`$/, '\1')          # Remove backticks
                              .strip

        # Validate table name (basic identifier rules)
        if table_name =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/
          table_name
        else
          nil
        end
      end
    end
  end
end
