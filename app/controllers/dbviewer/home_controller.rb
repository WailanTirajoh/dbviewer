module Dbviewer
  class HomeController < ApplicationController
    include Dbviewer::DatabaseOperations
    include Dbviewer::ErrorHandling

    # Action to show the homepage dashboard
    def index
      @tables = fetch_tables_with_stats(include_record_counts: true)
      @analytics = fetch_database_analytics
    rescue => e
      @tables = []
      @analytics = {
        total_tables: 0,
        total_records: 0,
        total_columns: 0,
        largest_tables: [],
        widest_tables: [],
        empty_tables: [],
        avg_records_per_table: 0,
        avg_columns_per_table: 0
      }
      log_error(e, "Database analytics fetch error")
    end
  end
end
