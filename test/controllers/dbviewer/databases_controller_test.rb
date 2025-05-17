require "test_helper"

module Dbviewer
  class DatabasesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @routes = Engine.routes
    end

    test "should get index" do
      get databases_url
      assert_response :success
      assert_select "h1", "Database Tables"
    end

    test "should get erd" do
      get erd_url
      assert_response :success
    end

    test "should get logs" do
      get logs_databases_url
      assert_response :success
    end

    test "should get show for a table" do
      # Mock a table name - implementation will depend on your test database
      table_name = "users"

      # You might need to stub this if the table doesn't exist in the test DB
      Dbviewer::DatabaseOperations.any_instance.stubs(:fetch_table_columns).returns([
        { name: "id", type: "integer" },
        { name: "name", type: "string" }
      ])

      get database_url(id: table_name)
      assert_response :success
    end
  end
end
