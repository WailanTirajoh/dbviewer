module Dbviewer
  class HomeController < ApplicationController
    def index
    end

    private

    def set_tables
      @tables = fetch_tables_with_stats(include_record_counts: true)
    end
  end
end
