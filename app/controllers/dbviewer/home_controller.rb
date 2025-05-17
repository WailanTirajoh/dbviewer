module Dbviewer
  class HomeController < ApplicationController
    skip_before_action :set_tables

    def index
      @tables = fetch_tables_with_stats(include_record_counts: true)
      @analytics = fetch_database_analytics
    end
  end
end
