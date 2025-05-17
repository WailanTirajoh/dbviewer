require "test_helper"

module Dbviewer
  class QueryLoggerTest < ActiveSupport::TestCase
    setup do
      # Reset the singleton instance for testing
      QueryLogger.instance_variable_set(:@singleton__instance__, nil)
      @logger = QueryLogger.instance

      # Stub out the collection to avoid ActiveSupport::Notifications in tests
      @mock_collection = Minitest::Mock.new
      @logger.instance_variable_set(:@collection, @mock_collection)
    end

    test "clear delegates to collection" do
      @mock_collection.expect :clear, nil
      @logger.clear
      @mock_collection.verify
    end

    test "recent_queries delegates to collection with correct parameters" do
      expected_args = { limit: 50, table_filter: "users", request_id: "123", min_duration: 10 }
      @mock_collection.expect :filter, [], [ expected_args ]

      @logger.recent_queries(
        limit: 50,
        table_filter: "users",
        request_id: "123",
        min_duration: 10
      )

      @mock_collection.verify
    end

    test "stats retrieves all queries from collection" do
      sample_queries = [ { duration_ms: 1.0 } ]
      @mock_collection.expect :all, sample_queries

      # We don't want to run the actual analysis in this test
      QueryAnalyzer.stub :generate_stats, { total_count: 1 } do
        stats = @logger.stats
        assert_equal({ total_count: 1 }, stats)
      end

      @mock_collection.verify
    end

    test "stats_for_queries delegates to QueryAnalyzer" do
      sample_queries = [ { duration_ms: 1.0 } ]

      QueryAnalyzer.stub :generate_stats, { total_count: 1 } do
        stats = @logger.stats_for_queries(sample_queries)
        assert_equal({ total_count: 1 }, stats)
      end
    end

    test "process_sql_event adds query to collection" do
      # Create a real collection for this test
      real_collection = QueryCollection.new
      @logger.instance_variable_set(:@collection, real_collection)

      # Create a mock event
      mock_event = Minitest::Mock.new
      mock_event.expect :payload, { sql: "SELECT 1", name: "Test", binds: [] }
      mock_event.expect :duration, 1.0

      # Process the event
      @logger.send(:process_sql_event, mock_event)

      # Verify the query was added
      queries = real_collection.all
      assert_equal 1, queries.size
      assert_equal "SELECT 1", queries.first[:sql]
      assert_equal "Test", queries.first[:name]
    end

    test "update_request_id creates new request IDs as needed" do
      # Initial call - should create a new request ID
      @logger.send(:update_request_id, Time.now)
      first_id = @logger.instance_variable_get(:@current_request_id)
      assert_match /^req-\d+-\d+$/, first_id

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
