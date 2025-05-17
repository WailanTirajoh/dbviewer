module Dbviewer
  # QueryAnalyzer handles analysis of query patterns and statistics
  class QueryAnalyzer
    # Calculate statistics for a collection of queries
    def self.generate_stats(queries)
      {
        total_count: queries.size,
        total_duration_ms: queries.sum { |q| q[:duration_ms] },
        avg_duration_ms: calculate_average_duration(queries),
        max_duration_ms: queries.map { |q| q[:duration_ms] }.max || 0,
        tables_queried: extract_queried_tables(queries),
        potential_n_plus_1: detect_potential_n_plus_1(queries),
        slowest_queries: get_slowest_queries(queries)
      }.merge(calculate_request_stats(queries))
    end

    # Detect potential N+1 query patterns
    def self.detect_potential_n_plus_1(queries)
      potential_issues = []

      # Group queries by request_id
      queries.group_by { |q| q[:request_id] }.each do |request_id, request_queries|
        # Skip if there are too few queries to indicate a problem
        next if request_queries.size < 5

        # Look for repeated patterns within this request
        analyze_request_patterns(request_id, request_queries, potential_issues)
      end

      # Sort by number of repetitions (most problematic first)
      potential_issues.sort_by { |issue| -issue[:count] }
    end

    # Get the slowest queries from the dataset
    def self.get_slowest_queries(queries, limit: 5)
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

    private

    def self.calculate_average_duration(queries)
      queries.any? ? (queries.sum { |q| q[:duration_ms] } / queries.size.to_f).round(2) : 0
    end

    def self.calculate_request_stats(queries)
      # Calculate request groups statistics
      requests = queries.group_by { |q| q[:request_id] }
      {
        request_count: requests.size,
        avg_queries_per_request: queries.any? ? (queries.size.to_f / requests.size).round(2) : 0,
        max_queries_per_request: requests.map { |_id, reqs| reqs.size }.max || 0
      }
    end

    def self.extract_queried_tables(queries)
      tables = Hash.new(0)

      queries.each do |query|
        extracted = QueryParser.extract_tables(query[:sql])
        extracted.each { |table| tables[table] += 1 }
      end

      tables.sort_by { |_table, count| -count }.first(10).to_h
    end

    def self.analyze_request_patterns(request_id, request_queries, potential_issues)
      # Group similar queries within this request
      patterns = {}

      request_queries.each do |query|
        # Normalize the query to detect patterns
        normalized = QueryParser.normalize(query[:sql])
        patterns[normalized] ||= []
        patterns[normalized] << query
      end

      # Look for patterns with many repetitions
      patterns.each do |pattern, pattern_queries|
        next if pattern_queries.size < 5  # Only interested in repeated patterns

        # Check if these queries target the same table
        tables = QueryParser.extract_tables(pattern_queries.first[:sql])
        target_table = tables.size == 1 ? tables.first : nil

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
  end
end
