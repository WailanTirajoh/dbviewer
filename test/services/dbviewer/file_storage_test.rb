require "test_helper"
require "tempfile"

module Dbviewer
  class FileStorageTest < ActiveSupport::TestCase
    setup do
      # Create a temporary file for testing
      @temp_file = Tempfile.new([ "dbviewer_query_log", ".log" ])

      # Store the original configuration
      @original_path = Dbviewer.configuration.query_log_path
      @original_mode = Dbviewer.configuration.query_logging_mode

      # Configure DBViewer to use our temporary file
      Dbviewer.configuration.query_log_path = @temp_file.path
      Dbviewer.configuration.query_logging_mode = :file

      @storage = FileStorage.new
    end

    teardown do
      # Close and delete the temporary file
      @temp_file.close
      @temp_file.unlink

      # Restore the original configuration
      Dbviewer.configuration.query_log_path = @original_path
      Dbviewer.configuration.query_logging_mode = @original_mode
    end

    test "add stores queries in the file" do
      @storage.add({ sql: "SELECT * FROM users", duration_ms: 10.5, timestamp: Time.now })

      # Read the file content
      content = File.read(@temp_file.path)
      assert_includes content, "SELECT * FROM users"
    end

    test "clear removes all queries" do
      @storage.add({ sql: "SELECT * FROM users", duration_ms: 10.5, timestamp: Time.now })
      @storage.clear

      assert_equal "", File.read(@temp_file.path).strip
    end

    test "all returns all stored queries" do
      timestamp = Time.now
      @storage.add({ sql: "SELECT * FROM users", duration_ms: 10.5, timestamp: timestamp })
      @storage.add({ sql: "SELECT * FROM orders", duration_ms: 5.2, timestamp: timestamp })

      queries = @storage.all
      assert_equal 2, queries.size
      assert_equal "SELECT * FROM users", queries[0][:sql]
      assert_equal "SELECT * FROM orders", queries[1][:sql]
    end

    test "filter by table returns matching queries" do
      timestamp = Time.now
      @storage.add({ sql: "SELECT * FROM users", duration_ms: 10.5, timestamp: timestamp })
      @storage.add({ sql: "SELECT * FROM orders", duration_ms: 5.2, timestamp: timestamp })

      result = @storage.filter(table_filter: "users")
      assert_equal 1, result.size
      assert_equal "SELECT * FROM users", result.first[:sql]
    end
  end
end
