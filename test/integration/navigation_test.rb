require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  include Dbviewer::Engine.routes.url_helpers

  setup do
    @routes = Dbviewer::Engine.routes
  end

  test "can navigate from dashboard to tables" do
    get root_url
    assert_response :success
    assert_select "h1", "Database Overview"

    # Find link to tables page and navigate to it
    assert_select "a[href=?]", databases_path
    get databases_url
    assert_response :success
    assert_select "h1", "Database Tables"
  end

  test "can navigate from tables to dashboard" do
    get databases_url
    assert_response :success
    assert_select "h1", "Database Tables"

    # Find link to dashboard page and navigate to it
    assert_select "a[href=?]", dashboard_path
    get root_url
    assert_response :success
    assert_select "h1", "Database Overview"
  end

  test "navigation links should have proper active classes" do
    # Dashboard page
    get root_url
    assert_select "a.nav-link.active", "Dashboard"

    # Tables page
    get databases_url
    assert_select "a.nav-link.active", "Tables"

    # ERD page
    get erd_url
    assert_select "a.nav-link.active", "ERD"

    # SQL Logs page
    get logs_databases_url
    assert_select "a.nav-link.active", "SQL Logs"
  end
end
