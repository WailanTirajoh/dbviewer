module Dbviewer
  module Storage
    # InMemoryStorage implements QueryStorage for storing queries in memory
    class InMemoryStorage < Base
      def initialize
        @queries = []
        @mutex = Mutex.new
      end

      # Get all queries
      def all
        @mutex.synchronize { @queries.dup }
      end

      # Add a new query to the collection
      def add(query)
        @mutex.synchronize do
          @queries << query
          # Trim if we have too many queries
          max_queries = Dbviewer.configuration.max_memory_queries || 1000
          @queries.shift if @queries.size > max_queries
        end
      end

      # Clear all stored queries
      def clear
        @mutex.synchronize { @queries.clear }
      end

      # Get recent queries, optionally filtered
      def filter(limit: 100, table_filter: nil, request_id: nil, min_duration: nil)
        result = all

        # Apply filters if provided
        result = filter_by_table(result, table_filter) if table_filter.present?
        result = filter_by_request_id(result, request_id) if request_id.present?
        result = filter_by_duration(result, min_duration) if min_duration.present?

        # Return most recent queries first, limited to requested amount
        result.reverse.first(limit)
      end

      private

      def filter_by_table(queries, table_filter)
        queries.select { |q| q[:sql].downcase.include?(table_filter.downcase) }
      end

      def filter_by_request_id(queries, request_id)
        queries.select { |q| q[:request_id].to_s.include?(request_id) }
      end

      def filter_by_duration(queries, min_duration)
        min_ms = min_duration.to_f
        queries.select { |q| q[:duration_ms] >= min_ms }
      end
    end
  end
end
