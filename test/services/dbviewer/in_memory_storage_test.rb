require "test_helper"

module Dbviewer
  class InMemoryStorageTest < ActiveSupport::TestCase
    setup do
      # Store original configuration
      @original_max = Dbviewer.configuration.max_memory_queries
      Dbviewer.configuration.max_memory_queries = 3

      @storage = InMemoryStorage.new
      @sample_queries = [
        { sql: "SELECT * FROM users", duration_ms: 10.5, request_id: "req-1" },
        { sql: "SELECT * FROM orders", duration_ms: 5.2, request_id: "req-1" }
      ]

      @sample_queries.each { |q| @storage.add(q) }
    end

    teardown do
      # Restore original configuration
      Dbviewer.configuration.max_memory_queries = @original_max
    end

    test "add stores queries in the collection" do
      assert_equal 2, @storage.all.size
    end

    test "clear removes all queries" do
      @storage.clear
      assert_empty @storage.all
    end

    test "filter by table returns matching queries" do
      result = @storage.filter(table_filter: "users")
      assert_equal 1, result.size
      assert_equal "SELECT * FROM users", result.first[:sql]
    end

    test "filter by request_id returns matching queries" do
      result = @storage.filter(request_id: "req-1")
      assert_equal 2, result.size
    end

    test "filter by min_duration returns queries with longer duration" do
      result = @storage.filter(min_duration: 10)
      assert_equal 1, result.size
      assert_equal "SELECT * FROM users", result.first[:sql]
    end

    test "collection enforces max size from configuration" do
      # Add more queries than the max_memory_queries limit (3)
      5.times { |i| @storage.add(sql: "Query #{i}") }

      # Should only contain the 3 most recent queries
      assert_equal 3, @storage.all.size
      assert_equal "Query 4", @storage.all.last[:sql]
    end
  end
end
