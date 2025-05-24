module Dbviewer
  class HomeController < ApplicationController
    def index
      # Load page immediately without heavy data
      # Data will be loaded asynchronously via AJAX
    end

    def analytics
      analytics_data = fetch_database_analytics
      # Remove record data which will be served by the records endpoint
      analytics_data.delete(:total_records)
      analytics_data.delete(:largest_tables)
      analytics_data.delete(:empty_tables)
      analytics_data.delete(:avg_records_per_table)

      respond_to do |format|
        format.json { render json: analytics_data }
      end
    end

    def records
      tables = fetch_tables_with_stats(include_record_counts: true)

      records_data = {
        total_records: tables.sum { |t| t[:record_count] },
        largest_tables: tables.sort_by { |t| -t[:record_count] }.first(10),
        empty_tables: tables.select { |t| t[:record_count] == 0 },
        avg_records_per_table: tables.any? ? (tables.sum { |t| t[:record_count] }.to_f / tables.size).round(1) : 0
      }

      respond_to do |format|
        format.json { render json: records_data }
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
