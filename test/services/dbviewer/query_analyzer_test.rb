require "test_helper"

module Dbviewer
  class QueryAnalyzerTest < ActiveSupport::TestCase
    setup do
      # Sample queries for testing
      @normal_queries = [
        { sql: "SELECT * FROM users WHERE id = 1", duration_ms: 5.2, request_id: "req-1", timestamp: Time.now, name: "User Load" },
        { sql: "SELECT * FROM orders WHERE user_id = 1", duration_ms: 3.1, request_id: "req-1", timestamp: Time.now, name: "Order Load" }
      ]

      # Sample N+1 query pattern
      @n_plus_1_queries = [
        { sql: "SELECT * FROM posts WHERE user_id = 1", duration_ms: 2.0, request_id: "req-2", timestamp: Time.now, name: "Post Load" },
        { sql: "SELECT * FROM comments WHERE post_id = 1", duration_ms: 1.0, request_id: "req-2", timestamp: Time.now, name: "Comment Load" },
        { sql: "SELECT * FROM comments WHERE post_id = 2", duration_ms: 1.1, request_id: "req-2", timestamp: Time.now, name: "Comment Load" },
        { sql: "SELECT * FROM comments WHERE post_id = 3", duration_ms: 1.2, request_id: "req-2", timestamp: Time.now, name: "Comment Load" },
        { sql: "SELECT * FROM comments WHERE post_id = 4", duration_ms: 1.3, request_id: "req-2", timestamp: Time.now, name: "Comment Load" },
        { sql: "SELECT * FROM comments WHERE post_id = 5", duration_ms: 1.4, request_id: "req-2", timestamp: Time.now, name: "Comment Load" }
      ]

      @all_queries = @normal_queries + @n_plus_1_queries
    end

    test "generate_stats returns complete statistics" do
      stats = QueryAnalyzer.generate_stats(@all_queries)

      assert_equal 8, stats[:total_count]
      assert_equal @all_queries.sum { |q| q[:duration_ms] }.round(2), stats[:total_duration_ms].round(2)
      assert stats[:avg_duration_ms].positive?
      assert stats[:max_duration_ms].positive?
      assert_equal 2, stats[:request_count]
    end

    test "detect_potential_n_plus_1 identifies repeated query patterns" do
      n_plus_1_issues = QueryAnalyzer.detect_potential_n_plus_1(@n_plus_1_queries)

      assert_equal 1, n_plus_1_issues.size
      assert_equal 5, n_plus_1_issues.first[:count]
      assert_equal "comments", n_plus_1_issues.first[:table]
    end

    test "get_slowest_queries returns the slowest queries" do
      slowest = QueryAnalyzer.get_slowest_queries(@all_queries, limit: 3)

      assert_equal 3, slowest.size
      assert_equal @normal_queries.first[:sql], slowest.first[:sql]
      assert_equal 5.2, slowest.first[:duration_ms]
    end

    test "extract_queried_tables counts tables correctly" do
      # Use the private method through the public API
      stats = QueryAnalyzer.generate_stats(@all_queries)
      tables = stats[:tables_queried]

      assert_equal 5, tables.size
      assert_equal 1, tables["users"]
      assert_equal 1, tables["orders"]
      assert_equal 1, tables["posts"]
      assert_equal 5, tables["comments"]
    end
  end
end
