module Dbviewer
  module Query
    # Parser handles parsing SQL queries and extracting useful information
    class Parser
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

      # Determine if a query should be skipped based on content
      # Rails and ActiveRecord often run internal queries that are not useful for logging
      # @param event [ActiveSupport::Notifications::Event] The notification event
      # @return [Boolean] True if the query should be skipped
      def self.should_skip_query?(event)
        event.payload[:name] == "SCHEMA" ||
        event.payload[:sql].include?("SHOW TABLES") ||
        event.payload[:sql].include?("sqlite_master") ||
        event.payload[:sql].include?("information_schema") ||
        event.payload[:sql].include?("schema_migrations") ||
        event.payload[:sql].include?("ar_internal_metadata") ||
        event.payload[:sql].include?("pg_catalog")
      end

      # Determine if an internal query should be skipped
      # Internal queries are those that are part of the Dbviewer module itself
      # and do not represent user-generated SQL queries.
      # This helps avoid logging internal operations that are not relevant to users.
      # @param event [ActiveSupport::Notifications::Event] The notification event
      # @return [Boolean] True if the query should be skipped
      def self.should_skip_internal_query?(event)
        event.payload[:name]&.include?("Dbviewer::") ||
        # SQLite specific check for size queries
        event.payload[:sql].include?("PRAGMA") ||
        # PostgreSQL specific check for size queries
        event.payload[:sql].include?("pg_database_size(current_database())") ||
        # MySQL specific check for size queries
        event.payload[:sql].include?("SUM(data_length + index_length) AS size FROM information_schema.TABLES")
      end
    end
  end
end
