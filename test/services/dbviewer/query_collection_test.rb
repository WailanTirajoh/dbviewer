require "test_helper"

module Dbviewer
  class QueryCollectionTest < ActiveSupport::TestCase
    setup do
      @collection = QueryCollection.new
      @sample_queries = [
        { sql: "SELECT * FROM users", duration_ms: 10.5, request_id: "req-1" },
        { sql: "SELECT * FROM orders", duration_ms: 5.2, request_id: "req-1" },
        { sql: "SELECT * FROM products", duration_ms: 15.7, request_id: "req-2" },
        { sql: "SELECT * FROM categories", duration_ms: 3.1, request_id: "req-2" }
      ]

      @sample_queries.each { |q| @collection.add(q) }
    end

    test "add stores queries in the collection" do
      assert_equal 4, @collection.all.size
    end

    test "clear removes all queries" do
      @collection.clear
      assert_empty @collection.all
    end

    test "filter by table returns matching queries" do
      result = @collection.filter(table_filter: "users")
      assert_equal 1, result.size
      assert_equal "SELECT * FROM users", result.first[:sql]
    end

    test "filter by request_id returns matching queries" do
      result = @collection.filter(request_id: "req-2")
      assert_equal 2, result.size
      assert_equal [ "SELECT * FROM products", "SELECT * FROM categories" ], result.map { |q| q[:sql] }
    end

    test "filter by min_duration returns queries with longer duration" do
      result = @collection.filter(min_duration: 10)
      assert_equal 2, result.size
      assert result.all? { |q| q[:duration_ms] >= 10 }
    end

    test "limit restricts the number of returned queries" do
      result = @collection.filter(limit: 2)
      assert_equal 2, result.size
    end

    test "queries are returned in reverse order (newest first)" do
      result = @collection.filter
      assert_equal "SELECT * FROM categories", result.first[:sql]
    end

    test "collection enforces max size" do
      # Add more queries than the MAX_QUERIES limit
      original_max = QueryCollection::MAX_QUERIES
      stub_const(QueryCollection, :MAX_QUERIES, 2) do
        collection = QueryCollection.new
        5.times { |i| collection.add(sql: "Query #{i}") }

        # Should only contain the 2 most recent queries
        assert_equal 2, collection.all.size
        assert_equal "Query 4", collection.all.first[:sql]
      end
    end

    private

    # Helper to temporarily modify constants for testing
    def stub_const(mod, constant, value)
      original = mod.const_get(constant)
      mod.send(:remove_const, constant)
      mod.const_set(constant, value)
      yield
    ensure
      mod.send(:remove_const, constant)
      mod.const_set(constant, original)
    end
  end
end
