module Dbviewer
  class HomeController < ApplicationController
    include Dbviewer::DatabaseOperations
    include Dbviewer::ErrorHandling

    # Action to show the homepage dashboard
    def index
      @tables = fetch_tables_with_stats(include_record_counts: true)
      @analytics = fetch_database_analytics
    end
  end
end
