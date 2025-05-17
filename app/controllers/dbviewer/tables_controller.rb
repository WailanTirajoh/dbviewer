module Dbviewer
  class TablesController < ApplicationController
    include Dbviewer::PaginationConcern

    def index
      @tables = fetch_tables_with_stats
    end

    def show
      @table_name = params[:id]
      @columns = fetch_table_columns(@table_name)
      @metadata = fetch_table_metadata(@table_name)
      @tables = fetch_tables_with_stats  # Fetch tables for sidebar

      set_pagination_params
      set_sorting_params

      @total_count = fetch_table_record_count(@table_name)
      @total_pages = calculate_total_pages(@total_count, @per_page)
      @records = fetch_table_records(@table_name)

      # Fetch timestamp visualization data if the table has a created_at column
      if has_timestamp_column?(@table_name)
        @time_grouping = params[:time_group] || "daily"
        @timestamp_data = fetch_timestamp_data(@table_name, @time_grouping)
      end
    end

    def query
      @table_name = params[:id]
      @read_only_mode = true # Flag to indicate we're in read-only mode
      @columns = fetch_table_columns(@table_name)
      @tables = fetch_tables_with_stats  # Fetch tables for sidebar

      # Set active table for sidebar highlighting
      @active_table = @table_name

      prepare_query
      execute_query

      render :query
    end

    def export_csv
      table_name = params[:id]
      limit = (params[:limit] || 10000).to_i
      include_headers = params[:include_headers] != "0"

      csv_data = export_table_to_csv(table_name, limit, include_headers)

      # Set filename with timestamp for uniqueness
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      filename = "#{table_name}_export_#{timestamp}.csv"

      # Send data as file
      send_data csv_data,
                type: "text/csv; charset=utf-8; header=present",
                disposition: "attachment; filename=#{filename}"
    end
  end
end
