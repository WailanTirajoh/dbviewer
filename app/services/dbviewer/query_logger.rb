module Dbviewer
  # QueryLogger captures and analyzes SQL queries for debugging and performance monitoring
  class QueryLogger
    include Singleton

    attr_reader :collection

    def initialize
      @collection = QueryCollection.new
      @request_counter = 0
      @current_request_id = nil
      @last_query_time = nil
      @mutex = Mutex.new

      subscribe_to_sql_notifications
    end

    # Clear all stored queries
    def clear
      collection.clear
    end

    # Get recent queries, optionally filtered
    def recent_queries(limit: 100, table_filter: nil, request_id: nil, min_duration: nil)
      collection.filter(
        limit: limit,
        table_filter: table_filter,
        request_id: request_id,
        min_duration: min_duration
      )
    end

    # Get stats about all queries
    def stats
      stats_for_queries(collection.all)
    end

    # Calculate stats for a specific set of queries (can be filtered)
    def stats_for_queries(queries)
      QueryAnalyzer.generate_stats(queries)
    end

    private

    def subscribe_to_sql_notifications
      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)

        # Skip internal queries and schema queries
        next if QueryParser.should_skip_query?(event)

        # Record the query details
        process_sql_event(event)
      end
    end

    def process_sql_event(event)
      @mutex.synchronize do
        current_time = Time.now
        update_request_id(current_time)
        @last_query_time = current_time

        # Create and store the query
        collection.add({
          sql: event.payload[:sql],
          name: event.payload[:name],
          timestamp: current_time,
          duration_ms: event.duration.round(2),
          binds: QueryParser.format_binds(event.payload[:binds]),
          request_id: @current_request_id,
          thread_id: Thread.current.object_id.to_s,
          caller: event.payload[:caller]
        })
      end
    end

    def update_request_id(current_time)
      # Generate a new request ID if:
      # 1. This is the first query, or
      # 2. More than 1 second has passed since the last query
      if @current_request_id.nil? || @last_query_time.nil? || (current_time - @last_query_time) > 1.0
        @current_request_id = "req-#{Time.now.to_i}-#{@request_counter += 1}"
      end
    end
  end
end
