module Dbviewer
  # Logger captures and analyzes SQL queries for debugging and performance monitoring
  class Logger
    include Singleton

    def initialize
      set_storage
      Rails.logger.info("[DBViewer] Query Logger initialized with #{mode} storage mode")
    end

    # Add a new SQL event query to the logger
    def add(event)
      # Return early if query logging is disabled
      return unless Dbviewer.configuration.enable_query_logging

      current_time = Time.now
      @storage.add({
        sql: event.payload[:sql],
        name: event.payload[:name],
        timestamp: current_time,
        duration_ms: event.duration.round(2),
        binds: QueryParser.format_binds(event.payload[:binds]),
        request_id: event.transaction_id || current_time.to_i,
        thread_id: Thread.current.object_id.to_s,
        caller: event.payload[:caller]
      })
    end

    # Clear all stored queries
    def clear
      @storage.clear
    end

    # Get recent queries, optionally filtered
    def recent_queries(limit: 100, table_filter: nil, request_id: nil, min_duration: nil)
      @storage.filter(
        limit: limit,
        table_filter: table_filter,
        request_id: request_id,
        min_duration: min_duration
      )
    end

    # Get stats about all queries
    def stats
      stats_for_queries(@storage.all)
    end

    # Calculate stats for a specific set of queries (can be filtered)
    def stats_for_queries(queries)
      QueryAnalyzer.generate_stats(queries)
    end

    class << self
      extend Forwardable

      # Delegate add method to the singleton instance so that it can be called directly on sql events
      def_delegators :instance, :add
    end

    private

    def mode
      @mode ||= Dbviewer.configuration.query_logging_mode || :memory
    end

    def set_storage
      @storage ||= case mode
      when :file
        Storage::FileStorage.new
      else
        Storage::InMemoryStorage.new
      end
    end
  end
end
