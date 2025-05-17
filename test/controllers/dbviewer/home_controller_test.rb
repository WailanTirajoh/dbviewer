require "test_helper"

module Dbviewer
  class HomeControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @routes = Engine.routes
    end

    test "should get index" do
      get root_url
      assert_response :success
      assert_select "h1", "Database Overview"
      assert_select ".card", { minimum: 4 }, "Should have dashboard cards for analytics"
    end

    test "should handle database errors gracefully" do
      Dbviewer::DatabaseOperations.any_instance.stubs(:fetch_tables_with_stats).raises(StandardError, "Test error")

      get root_url
      assert_response :success

      # Should still render the page without crashing
      assert_select "h1", "Database Overview"
    end
  end
end
