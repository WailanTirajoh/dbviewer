require "test_helper"

module Dbviewer
  class QueryParserTest < ActiveSupport::TestCase
    test "extract_tables correctly identifies table names" do
      sql = "SELECT * FROM users JOIN orders ON users.id = orders.user_id WHERE status = 'pending'"
      tables = QueryParser.extract_tables(sql)

      assert_equal 2, tables.size
      assert_includes tables, "users"
      assert_includes tables, "orders"
    end

    test "normalize correctly replaces variable parts of queries" do
      sql = "SELECT * FROM users WHERE id = 123 AND name = 'John Doe' AND status = \"active\""
      normalized = QueryParser.normalize(sql)

      assert_includes normalized, "id = N"
      assert_includes normalized, "name = 'X'"
      assert_includes normalized, "status = \"X\""
    end

    test "format_binds handles different bind parameter formats" do
      # Test with objects that respond to value
      bind_with_value = Minitest::Mock.new
      bind_with_value.expect :value, "test_value"
      bind_with_value.expect :respond_to?, true, [ :value ]

      # Test with array format
      bind_as_array = [ "column_name", "array_value" ]

      # Test with other objects
      bind_as_other = Object.new

      binds = [ bind_with_value, bind_as_array, bind_as_other ]
      formatted = QueryParser.format_binds(binds)

      assert_equal 3, formatted.size
      assert_equal "test_value", formatted[0]
      assert_equal "array_value", formatted[1]
      assert_equal bind_as_other.to_s, formatted[2]
    end

    test "should_skip_query? correctly identifies system queries" do
      event = create_mock_event("SCHEMA", "SELECT * FROM sqlite_master")
      assert QueryParser.should_skip_query?(event)

      event = create_mock_event("ProductsController", "SELECT * FROM products")
      refute QueryParser.should_skip_query?(event)
    end

    private

    def create_mock_event(name, sql)
      event = Minitest::Mock.new
      payload = { name: name, sql: sql }
      event.expect :payload, payload
      event
    end
  end
end
