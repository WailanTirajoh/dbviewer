module Dbviewer
  class HomeController < ApplicationController
    def index
      @analytics = fetch_database_analytics
      if Dbviewer.configuration.enable_query_logging
        @recent_queries = Dbviewer::Logger.instance.recent_queries(limit: 10)
      end
    end

    private

    def set_tables
      @tables = fetch_tables_with_stats(include_record_counts: true)
    end
  end
end
