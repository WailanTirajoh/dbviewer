require "singleton"
require "forwardable"

module Dbviewer
  module Query
    # Logger captures and analyzes SQL queries for debugging and performance monitoring
    class Logger
      include Singleton

      def initialize
        # Initialize with default values, will be configured later
        @enable_query_logging = true
        @query_logging_mode = :memory
        set_storage
        Rails.logger.info("[DBViewer] QueryLogger initialized with #{mode} storage mode")
      end

      # Configure the logger with settings
      # @param enable_query_logging [Boolean] Whether query logging is enabled
      # @param query_logging_mode [Symbol] Storage mode (:memory or :file)
      def configure(enable_query_logging: true, query_logging_mode: :memory)
        @enable_query_logging = enable_query_logging
        @query_logging_mode = query_logging_mode
        # Reinitialize storage if mode changed
        @storage = nil
        @mode = nil
        set_storage
        Rails.logger.info("[DBViewer] QueryLogger configured with #{mode} storage mode")
      end

      # Add a new SQL event query to the logger
      def add(event)
        # Return early if query logging is disabled
        return unless @enable_query_logging
        return if ::Dbviewer::Query::Parser.should_skip_query?(event) || ::Dbviewer::Query::Parser.should_skip_internal_query?(event)

        current_time = Time.now
        @storage.add({
          sql: event.payload[:sql],
          name: event.payload[:name],
          timestamp: current_time,
          duration_ms: event.duration.round(2),
          binds: ::Dbviewer::Query::Parser.format_binds(event.payload[:binds]),
          request_id: ActiveSupport::Notifications.instrumenter.id,
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
        Analyzer.generate_stats(queries)
      end

      class << self
        extend Forwardable

        # Delegate add method to the singleton instance so that it can be called directly on sql events
        def_delegators :instance, :add

        # Configure the singleton instance
        # @param enable_query_logging [Boolean] Whether query logging is enabled
        # @param query_logging_mode [Symbol] Storage mode (:memory or :file)
        def configure(enable_query_logging: true, query_logging_mode: :memory)
          instance.configure(
            enable_query_logging: enable_query_logging,
            query_logging_mode: query_logging_mode
          )
        end
      end

      private

      def mode
        @mode ||= @query_logging_mode || :memory
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
end
