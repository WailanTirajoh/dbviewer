require "test_helper"

module Dbviewer
  class QueryLoggerTest < ActiveSupport::TestCase
    setup do
      # Store original configuration
      @original_mode = Dbviewer.configuration.query_logging_mode
      Dbviewer.configuration.query_logging_mode = :memory

      # Reset the singleton instance for testing
      QueryLogger.instance_variable_set(:@singleton__instance__, nil)
      @logger = QueryLogger.instance

      # Stub out the storage to avoid ActiveSupport::Notifications in tests
      @mock_storage = Minitest::Mock.new
      @logger.instance_variable_set(:@storage, @mock_storage)
    end

    teardown do
      # Restore original configuration
      Dbviewer.configuration.query_logging_mode = @original_mode
    end

    test "clear delegates to storage" do
      @mock_storage.expect :clear, nil
      @logger.clear
      @mock_storage.verify
    end

    test "recent_queries delegates to storage with correct parameters" do
      expected_args = { limit: 50, table_filter: "users", request_id: "123", min_duration: 10 }
      @mock_storage.expect :filter, [], [ expected_args ]

      @logger.recent_queries(
        limit: 50,
        table_filter: "users",
        request_id: "123",
        min_duration: 10
      )

      @mock_storage.verify
    end

    test "stats retrieves all queries from storage" do
      sample_queries = [ { duration_ms: 1.0 } ]
      @mock_storage.expect :all, sample_queries

      # We don't want to run the actual analysis in this test
      QueryAnalyzer.stub :generate_stats, { total_count: 1 } do
        stats = @logger.stats
        assert_equal({ total_count: 1 }, stats)
      end

      @mock_storage.verify
    end

    test "stats_for_queries delegates to QueryAnalyzer" do
      sample_queries = [ { duration_ms: 1.0 } ]

      QueryAnalyzer.stub :generate_stats, { total_count: 1 } do
        stats = @logger.stats_for_queries(sample_queries)
        assert_equal({ total_count: 1 }, stats)
      end
    end

    test "process_sql_event adds query to storage" do
      # Create a real storage for this test
      real_storage = InMemoryStorage.new
      @logger.instance_variable_set(:@storage, real_storage)

      # Create a mock event
      mock_event = Minitest::Mock.new
      mock_event.expect :payload, { sql: "SELECT 1", name: "Test", binds: [] }
      mock_event.expect :duration, 1.0

      # Process the event
      @logger.send(:process_sql_event, mock_event)

      # Verify the query was added
      queries = real_storage.all
      assert_equal 1, queries.size
      assert_equal "SELECT 1", queries.first[:sql]
      assert_equal "Test", queries.first[:name]
    end

    test "update_request_id creates new request IDs as needed" do
      # Initial call - should create a new request ID
      @logger.send(:update_request_id, Time.now)
      first_id = @logger.instance_variable_get(:@current_request_id)
      assert_match(/^req-\d+-\d+$/, first_id)

      # Quick second call - should use the same ID
      @logger.send(:update_request_id, Time.now)
      second_id = @logger.instance_variable_get(:@current_request_id)
      assert_equal first_id, second_id

      # Call after delay - should create a new ID
      @logger.instance_variable_set(:@last_query_time, Time.now - 2)
      @logger.send(:update_request_id, Time.now)
      third_id = @logger.instance_variable_get(:@current_request_id)
      refute_equal first_id, third_id
    end
  end
end
