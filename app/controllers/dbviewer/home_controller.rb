module Dbviewer
  class HomeController < ApplicationController
    def index
      @current_connection_info = {
        name: get_database_name,
        adapter: get_adapter_name,
        key: current_connection_key
      }
    end

    private

    def set_tables
      @tables = fetch_tables(include_record_counts: true)
    end
  end
end
