require "test_helper"

module Dbviewer
  class DatabaseOperationsTest < ActionController::TestCase
    class TestController < Dbviewer::ApplicationController
      include Dbviewer::DatabaseOperations

      def test_action
        @database_name = get_database_name
        render plain: @database_name
      end
    end

    tests TestController

    test "get_database_name returns a non-empty string" do
      with_routing do |set|
        set.draw { get "test_action" => "dbviewer/database_operations_test/test#test_action" }
        get :test_action

        assert_response :success
        assert_not_empty @response.body, "Database name should not be empty"
      end
    end

    test "get_database_name handles errors gracefully" do
      test_controller = TestController.new
      mock_database_manager = Minitest::Mock.new
      error = StandardError.new("Database connection error")

      mock_database_manager.expect :connection, nil do
        raise error
      end

      test_controller.stub :database_manager, mock_database_manager do
        assert_equal "Database", test_controller.get_database_name
      end
    end

    test "get_database_name can handle long database names" do
      test_controller = TestController.new

      # Create mock connection and database manager
      mock_connection = Minitest::Mock.new
      mock_connection.expect :adapter_name, "mysql2"

      mock_database_manager = Minitest::Mock.new
      mock_database_manager.expect :connection, mock_connection

      # Result with a long database name
      long_name = "very_long_database_name_for_testing_truncation_in_ui"
      result = { "db_name" => long_name }

      mock_database_manager.expect :execute_query, [ result ], [ "SELECT DATABASE() as db_name" ]

      test_controller.stub :database_manager, mock_database_manager do
        assert_equal long_name, test_controller.get_database_name
      end
    end
  end
end
