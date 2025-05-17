module Dbviewer
  class QueryLogger
    include Singleton

    # Maximum number of queries to keep in memory
    MAX_QUERIES = 1000

    attr_reader :queries

    def initialize
      @queries = []
      @mutex = Mutex.new
      @request_counter = 0
      @current_request_id = nil
      @last_query_time = nil

      subscribe_to_sql_notifications
    end

    # Clear all stored queries
    def clear
      @mutex.synchronize { @queries.clear }
    end

    # Get recent queries, optionally filtered
    def recent_queries(limit: 100, table_filter: nil, request_id: nil, min_duration: nil)
      result = @mutex.synchronize { @queries.dup }

      # Apply filters if provided
      if table_filter.present?
        result = result.select { |q| q[:sql].downcase.include?(table_filter.downcase) }
      end

      if request_id.present?
        result = result.select { |q| q[:request_id].to_s.include?(request_id) }
      end

      if min_duration.present?
        min_ms = min_duration.to_f
        result = result.select { |q| q[:duration_ms] >= min_ms }
      end

      # Return most recent queries first, limited to requested amount
      result.reverse.first(limit)
    end

    # Get stats about all queries
    def stats
      queries_copy = @mutex.synchronize { @queries.dup }
      stats_for_queries(queries_copy)
    end

    # Calculate stats for a specific set of queries (can be filtered)
    def stats_for_queries(queries)
      result = {
        total_count: queries.size,
        total_duration_ms: queries.sum { |q| q[:duration_ms] },
        avg_duration_ms: queries.any? ? (queries.sum { |q| q[:duration_ms] } / queries.size.to_f).round(2) : 0,
        max_duration_ms: queries.map { |q| q[:duration_ms] }.max || 0,
        tables_queried: extract_queried_tables(queries),
        potential_n_plus_1: detect_potential_n_plus_1(queries),
        slowest_queries: get_slowest_queries(queries)
      }

      # Calculate request groups statistics
      requests = queries.group_by { |q| q[:request_id] }
      result[:request_count] = requests.size
      result[:avg_queries_per_request] = queries.any? ? (queries.size.to_f / requests.size).round(2) : 0
      result[:max_queries_per_request] = requests.map { |_id, queries| queries.size }.max || 0

      result
    end

    # Detect potential N+1 query patterns
    def detect_potential_n_plus_1(queries)
      potential_issues = []

      # Group queries by request_id
      by_request = queries.group_by { |q| q[:request_id] }

      by_request.each do |request_id, request_queries|
        # Skip if there are too few queries to indicate a problem
        next if request_queries.size < 5

        # Group similar queries within this request
        patterns = {}

        request_queries.each do |query|
          # Normalize the query to detect patterns
          # Replace numbers/IDs with placeholders to group similar queries
          normalized = query[:sql]
            .gsub(/\b\d+\b/, "N")
            .gsub(/'[^']*'/, "'X'")
            .gsub(/"[^"]*"/, '"X"')

          patterns[normalized] ||= []
          patterns[normalized] << query
        end

        # Look for patterns with many repetitions
        patterns.each do |pattern, pattern_queries|
          next if pattern_queries.size < 5  # Only interested in repeated patterns

          # Check if these queries target the same table
          target_table = nil
          tables = extract_tables_from_sql(pattern)

          if tables.size == 1
            target_table = tables.first
          end

          # Add to potential issues
          total_time = pattern_queries.sum { |q| q[:duration_ms] }
          potential_issues << {
            request_id: request_id,
            pattern: pattern_queries.first[:sql],
            count: pattern_queries.size,
            table: target_table,
            total_duration_ms: total_time.round(2),
            avg_duration_ms: (total_time / pattern_queries.size).round(2)
          }
        end
      end

      # Sort by number of repetitions (most problematic first)
      potential_issues.sort_by { |issue| -issue[:count] }
    end

    private

    def subscribe_to_sql_notifications
      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)

        # Skip internal queries and schema queries
        next if event.payload[:name] == "SCHEMA" ||
                event.payload[:sql].include?("SHOW TABLES") ||
                event.payload[:sql].include?("sqlite_master") ||
                event.payload[:sql].include?("information_schema") ||
                event.payload[:sql].include?("pg_catalog") ||
                from_dbviewer?(event)

        # Record the query details
        @mutex.synchronize do
          current_time = Time.now

          # Generate a new request ID if:
          # 1. This is the first query, or
          # 2. More than 1 second has passed since the last query
          if @current_request_id.nil? || @last_query_time.nil? || (current_time - @last_query_time) > 1.0
            @current_request_id = "req-#{Time.now.to_i}-#{@request_counter += 1}"
          end

          @last_query_time = current_time

          # Add the query with request ID information
          @queries << {
            sql: event.payload[:sql],
            name: event.payload[:name],
            timestamp: current_time,
            duration_ms: event.duration.round(2),
            binds: format_binds(event.payload[:binds]),
            request_id: @current_request_id,
            thread_id: Thread.current.object_id.to_s,
            caller: event.payload[:caller]
          }

          # Trim if we have too many queries
          @queries.shift if @queries.size > MAX_QUERIES
        end
      end
    end

    def format_binds(binds)
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

    def extract_queried_tables(queries)
      tables = Hash.new(0)

      queries.each do |query|
        extracted = extract_tables_from_sql(query[:sql])
        extracted.each { |table| tables[table] += 1 }
      end

      tables.sort_by { |_table, count| -count }.first(10).to_h
    end

    # Get the slowest queries from the dataset
    def get_slowest_queries(queries, limit: 5)
      # Return top N slowest queries with relevant info
      queries.sort_by { |q| -q[:duration_ms] }
        .first(limit)
        .map do |q|
          {
            sql: q[:sql],
            duration_ms: q[:duration_ms],
            timestamp: q[:timestamp],
            request_id: q[:request_id],
            name: q[:name]
          }
        end
    end

    # Check if the query is from the DBViewer library
    def from_dbviewer?(event)
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

    # Extract table names from an SQL query string
    def extract_tables_from_sql(sql)
      # Simple regex to find table names in SQL
      # This is a basic implementation and might miss some tables depending on SQL complexity
      sql = sql.downcase

      # Extract table names after FROM or JOIN
      sql.scan(/(?:from|join)\s+[`"']?(\w+)[`"']?/).flatten.uniq
    end
  end
end
