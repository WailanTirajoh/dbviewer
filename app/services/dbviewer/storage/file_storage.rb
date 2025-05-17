require "json"
require "time"

module Dbviewer
  module Storage
    # FileStorage implements QueryStorage for storing queries in a log file
    class FileStorage < Base
      def initialize
        @mutex = Mutex.new
        @log_path = Dbviewer.configuration.query_log_path || "log/dbviewer.log"

        # Ensure directory exists
        FileUtils.mkdir_p(File.dirname(@log_path))

        # Touch the file if it doesn't exist
        FileUtils.touch(@log_path) unless File.exist?(@log_path)
      end

      # Get all stored queries
      # Note: This reads the entire log file - could be inefficient for large files
      def all
        @mutex.synchronize do
          read_queries_from_file
        end
      end

      # Add a new query to the storage
      def add(query)
        @mutex.synchronize do
          # Convert query to JSON and append to file
          query_json = query.to_json
          File.open(@log_path, "a") do |file|
            file.puts(query_json)
          end
        end
      end

      # Clear all stored queries
      def clear
        @mutex.synchronize do
          # Simply truncate the file
          File.open(@log_path, "w") { }
        end
      end

      # Filter the queries based on provided criteria
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

      def read_queries_from_file
        queries = []

        # Read the file line by line and parse each line as JSON
        File.foreach(@log_path) do |line|
          begin
            query = JSON.parse(line.strip, symbolize_names: true)

            # Convert timestamp strings back to Time objects
            query[:timestamp] = Time.parse(query[:timestamp]) if query[:timestamp].is_a?(String)

            queries << query
          rescue JSON::ParserError => e
            # Skip malformed lines
            Rails.logger.warn("Skipping malformed query log entry: #{e.message}")
          end
        end

        queries
      end

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
