module Dbviewer
  # QueryCollection handles the storage and retrieval of SQL queries
  # This class is maintained for backward compatibility
  # New code should use InMemoryStorage or FileStorage directly
  class QueryCollection < InMemoryStorage
    # Maximum number of queries to keep in memory
    MAX_QUERIES = 1000

    def initialize
      super
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
