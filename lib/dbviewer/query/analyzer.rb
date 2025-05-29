module Dbviewer
  module Query
    # Analyzer handles analysis of query patterns and statistics
    class Analyzer
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

      # Instance methods for query analysis
      attr_reader :connection, :adapter_name

      # Initialize the analyzer for instance methods
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      def initialize(connection)
        @connection = connection
        @adapter_name = connection.adapter_name.downcase
      end

      # Check if a table has an index on a column
      # @param table_name [String] Name of the table
      # @param column_name [String] Name of the column
      # @return [Boolean] True if column has an index, false otherwise
      def has_index_on?(table_name, column_name)
        indexes = connection.indexes(table_name)
        indexes.any? do |index|
          index.columns.include?(column_name) ||
          (index.columns.length == 1 && index.columns[0] == column_name)
        end
      end

      # Analyze a query and provide performance statistics and recommendations
      # @param table_name [String] Name of the table
      # @param query_params [Dbviewer::Datatable::QueryParams] Query parameters with filters
      # @return [Hash] Analysis results with statistics and recommendations
      def analyze_query(table_name, query_params)
        results = {
          table: table_name,
          filters: query_params.column_filters.keys,
          analysis: [],
          recommendations: []
        }

        # Check created_at filter performance
        if query_params.column_filters.key?("created_at")
          analyze_timestamp_query(table_name, "created_at", results)
        end

        # Check updated_at filter performance
        if query_params.column_filters.key?("updated_at")
          analyze_timestamp_query(table_name, "updated_at", results)
        end

        # Check other filters for potential indexes
        query_params.column_filters.each do |column_name, _value|
          next if [ "created_at", "updated_at" ].include?(column_name)

          unless has_index_on?(table_name, column_name)
            results[:recommendations] << {
              type: "missing_index",
              message: "Consider adding an index on '#{column_name}' for faster filtering",
              sql: index_creation_sql(table_name, column_name)
            }
          end
        end

        # Add database-specific recommendations
        add_database_specific_recommendations(results)

        results
      end

      private

      # Analyze timestamp-based queries
      def analyze_timestamp_query(table_name, column_name, results)
        # Check if column exists
        unless connection.column_exists?(table_name, column_name)
          results[:analysis] << "Column '#{column_name}' not found in table '#{table_name}'"
          return
        end

        # Check if there's an index on the timestamp column
        unless has_index_on?(table_name, column_name)
          results[:recommendations] << {
            type: "missing_index",
            message: "Consider adding an index on '#{column_name}' for faster filtering",
            sql: index_creation_sql(table_name, column_name)
          }
        end

        # Estimate data distribution if possible
        if adapter_supports_statistics?(adapter_name)
          add_data_distribution_stats(table_name, column_name, results)
        end
      rescue => e
        results[:analysis] << "Error analyzing timestamp query: #{e.message}"
      end

      # Check if adapter supports statistics gathering
      def adapter_supports_statistics?(adapter_name)
        adapter_name.include?("postgresql")
      end

      # Add data distribution statistics
      def add_data_distribution_stats(table_name, column_name, results)
        case adapter_name
        when /postgresql/
          begin
            # Get approximate date range and distribution
            range_query = "SELECT min(#{column_name}), max(#{column_name}) FROM #{table_name}"
            range_result = connection.execute(range_query).first

            if range_result["min"] && range_result["max"]
              min_date = range_result["min"]
              max_date = range_result["max"]

              results[:analysis] << {
                type: "date_range",
                min_date: min_date,
                max_date: max_date,
                span_days: ((Time.parse(max_date) - Time.parse(min_date)) / 86400).round
              }
            end
          rescue => e
            results[:analysis] << "Error getting date distribution: #{e.message}"
          end
        end
      end

      # Generate SQL for index creation
      def index_creation_sql(table_name, column_name)
        index_name = "index_#{table_name.gsub('.', '_')}_on_#{column_name}"
        "CREATE INDEX #{index_name} ON #{table_name} (#{column_name})"
      end

      # Add database-specific recommendations
      def add_database_specific_recommendations(results)
        case adapter_name
        when /mysql/
          results[:recommendations] << {
            type: "performance",
            message: "For MySQL, consider optimizing the query with appropriate indexes and use EXPLAIN to verify query plan"
          }
        when /postgresql/
          results[:recommendations] << {
            type: "performance",
            message: "For PostgreSQL, consider using EXPLAIN ANALYZE to verify query execution plan"
          }
        when /sqlite/
          results[:recommendations] << {
            type: "performance",
            message: "For SQLite, consider using EXPLAIN QUERY PLAN to verify query execution strategy"
          }
        end
      end

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
          extracted = ::Dbviewer::QueryParser.extract_tables(query[:sql])
          extracted.each { |table| tables[table] += 1 }
        end

        tables.sort_by { |_table, count| -count }.first(10).to_h
      end

      def self.detect_potential_n_plus_1(queries)
        return [] if queries.empty?

        potential_issues = []

        # Group queries by request ID
        requests = queries.group_by { |q| q[:request_id] }

        requests.each do |request_id, request_queries|
          analyze_request_patterns(request_id, request_queries, potential_issues)
        end

        potential_issues.sort_by { |issue| -issue[:total_duration_ms] }.first(10)
      end

      def self.get_slowest_queries(queries)
        queries.sort_by { |q| -q[:duration_ms] }.first(10).map do |query|
          {
            sql: query[:sql],
            duration_ms: query[:duration_ms],
            request_id: query[:request_id],
            timestamp: query[:timestamp]
          }
        end
      end

      def self.analyze_request_patterns(request_id, request_queries, potential_issues)
        # Group similar queries within this request
        patterns = {}

        request_queries.each do |query|
          # Normalize the query to detect patterns
          normalized = ::Dbviewer::QueryParser.normalize(query[:sql])
          patterns[normalized] ||= []
          patterns[normalized] << query
        end

        # Look for patterns with many repetitions
        patterns.each do |pattern, pattern_queries|
          next if pattern_queries.size < 5  # Only interested in repeated patterns

          # Check if these queries target the same table
          tables = ::Dbviewer::QueryParser.extract_tables(pattern_queries.first[:sql])
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
end
