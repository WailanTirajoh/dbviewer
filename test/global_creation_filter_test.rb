# frozen_string_literal: true

require "test_helper"

module Dbviewer
  class GlobalCreationFilterTest < ActiveSupport::TestCase
    setup do
      # Ensure we have a database manager
      @database_manager = Dbviewer::Database::Manager.new
      @query_operations = @database_manager.table_query_operations

      # Store adapter name for conditional testing
      @adapter_name = @database_manager.connection.adapter_name.downcase
    end

    test "should apply creation filter to table with created_at column" do
      test_table = nil

      # Find a table with a created_at column
      @database_manager.tables.each do |table|
        columns = @database_manager.table_columns(table)
        if columns.any? { |col| col[:name] == "created_at" && [ :datetime, :timestamp ].include?(col[:type]) }
          test_table = table
          break
        end
      end

      # Skip test if no table with created_at column is found
      skip "No table with created_at column found" unless test_table

      # Get total count without filters
      total_count = @query_operations.table_count(test_table)
      return if total_count == 0 # Skip if no records

      # Get one record to extract its created_at value
      records = @query_operations.table_records(
        test_table,
        Dbviewer::Datatable::QueryParams.new(page: 1, per_page: 1, column_filters: {})
      )

      created_at = nil
      records.rows.each do |row|
        created_at_index = records.columns.index("created_at")
        created_at = row[created_at_index] if created_at_index
        break
      end

      return if created_at.nil? # Skip if no created_at value found

      # Parse date and create a range
      begin
        timestamp = Time.parse(created_at.to_s)
        start_date = (timestamp - 1.day).iso8601
        end_date = (timestamp + 1.day).iso8601
      rescue => e
        skip "Failed to parse timestamp: #{e.message}"
      end

      # Create filter params
      column_filters = {
        "created_at" => start_date,
        "created_at_end" => end_date
      }

      # Apply filter
      filtered_count = @query_operations.filtered_record_count(test_table, column_filters)

      # Assert that filter works (filtered count should be less than or equal to total)
      assert filtered_count <= total_count

      # Get filtered records
      filtered_records = @query_operations.table_records(
        test_table,
        Dbviewer::Datatable::QueryParams.new(page: 1, per_page: 10, column_filters: column_filters)
      )

      # For each row, verify that created_at is within range
      created_at_index = filtered_records.columns.index("created_at")
      if created_at_index
        filtered_records.rows.each do |row|
          row_created_at = row[created_at_index]
          next if row_created_at.nil?

          row_timestamp = Time.parse(row_created_at.to_s)
          start_timestamp = Time.parse(start_date)
          end_timestamp = Time.parse(end_date)

          assert row_timestamp >= start_timestamp, "Record created_at is before filter start date"
          assert row_timestamp <= end_timestamp, "Record created_at is after filter end date"
        end
      end
    end

    test "table without created_at column should not be affected by creation filter" do
      test_table = nil

      # Find a table without a created_at column
      @database_manager.tables.each do |table|
        columns = @database_manager.table_columns(table)
        unless columns.any? { |col| col[:name] == "created_at" }
          test_table = table
          break
        end
      end

      # Skip test if no table without created_at column is found
      skip "No table without created_at column found" unless test_table

      # Create filter params
      column_filters = {
        "created_at" => "2023-01-01T00:00:00",
        "created_at_end" => "2023-12-31T23:59:59"
      }

      # Get total count without filters
      total_count = @query_operations.table_count(test_table)

      # Apply filter
      filtered_count = @query_operations.filtered_record_count(test_table, column_filters)

      # Assert that filter has no effect (filtered count should be equal to total)
      assert_equal total_count, filtered_count
    end

    test "creation filter should work with different database adapters" do
      # This test verifies that datetime handling is appropriate for the current database adapter

      case @adapter_name
      when /sqlite/
        # For SQLite, test ISO8601 format parsing
        assert_datetime_filtering_works("2023-01-01T00:00:00", "2023-12-31T23:59:59")
      when /mysql/
        # For MySQL, test standard MySQL datetime format
        assert_datetime_filtering_works("2023-01-01 00:00:00", "2023-12-31 23:59:59")
      when /postgre/
        # For PostgreSQL, test timestamp format
        assert_datetime_filtering_works("2023-01-01 00:00:00", "2023-12-31 23:59:59")
      else
        skip "Unknown database adapter: #{@adapter_name}"
      end
    end

    private

    def assert_datetime_filtering_works(start_date, end_date)
      test_table = nil

      # Find a table with a created_at column
      @database_manager.tables.each do |table|
        columns = @database_manager.table_columns(table)
        if columns.any? { |col| col[:name] == "created_at" && [ :datetime, :timestamp ].include?(col[:type]) }
          test_table = table
          break
        end
      end

      skip "No table with created_at column found" unless test_table

      # Create filter params
      column_filters = {
        "created_at" => start_date,
        "created_at_end" => end_date
      }

      # Apply filter - no exception should be raised
      begin
        @query_operations.filtered_record_count(test_table, column_filters)
        pass # If we got here, the test passes
      rescue => e
        flunk "Database adapter #{@adapter_name} failed with dates #{start_date} and #{end_date}: #{e.message}"
      end
    end
  end
end
