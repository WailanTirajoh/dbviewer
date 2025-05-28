module Dbviewer
  # QueryParser handles parsing SQL queries and extracting useful information
  class QueryParser
    # Extract table names from an SQL query string
    def self.extract_tables(sql)
      return [] if sql.nil?

      # Convert to lowercase for case-insensitive matching
      sql = sql.downcase

      # Extract table names after FROM or JOIN
      sql.scan(/(?:from|join)\s+[`"']?(\w+)[`"']?/).flatten.uniq
    end

    # Normalize a SQL query to find similar patterns
    # Replaces specific values with placeholders
    def self.normalize(sql)
      return "" if sql.nil?

      sql.gsub(/\b\d+\b/, "N")
         .gsub(/'[^']*'/, "'X'")
         .gsub(/"[^"]*"/, '"X"')
    end

    # Check if the query is from the DBViewer library
    def self.from_dbviewer?(event)
      # Check if the SQL itself references DBViewer tables
      if event.payload[:sql].match(/\b(from|join|update|into)\s+["`']?dbviewer_/i)
        return true
      end

      # Check the caller information if available
      caller = event.payload[:caller]
      if caller.is_a?(String) && caller.include?("/dbviewer/")
        return true
      end

      # Check if query name indicates it's from DBViewer
      if event.payload[:name].is_a?(String) &&
         (event.payload[:name].include?("Dbviewer") || event.payload[:name].include?("DBViewer") || event.payload[:name] == "SQL")
        return true
      end

      # Check for common DBViewer operations
      sql = event.payload[:sql].downcase
      if sql.include?("table_structure") ||
         sql.include?("schema_migrations") ||
         sql.include?("database_analytics")
        return true
      end

      false
    end

    # Format bind parameters for storage
    def self.format_binds(binds)
      return [] unless binds.respond_to?(:map)

      binds.map do |bind|
        if bind.respond_to?(:value)
          bind.value
        elsif bind.is_a?(Array) && bind.size == 2
          bind.last
        else
          bind.to_s
        end
      end
    rescue
      []
    end
  end
end
