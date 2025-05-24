module Dbviewer
  class HomeController < ApplicationController
    def index
      # Load page immediately without heavy data
      # Data will be loaded asynchronously via AJAX
    end

    def analytics
      @analytics = fetch_database_analytics

      respond_to do |format|
        format.json { render json: @analytics }
      end
    end

    def recent_queries
      @recent_queries = if Dbviewer.configuration.enable_query_logging
        Dbviewer::Logger.instance.recent_queries(limit: 10)
      else
        []
      end

      respond_to do |format|
        format.json do
          render json: {
            enabled: Dbviewer.configuration.enable_query_logging,
            queries: @recent_queries
          }
        end
      end
    end

    private

    def set_tables
      @tables = fetch_tables_with_stats(include_record_counts: true)
    end
  end
end
