module Dbviewer
  class TablesController < ApplicationController
    include Dbviewer::PaginationConcern

    def index
      @tables = fetch_tables_with_stats(include_record_counts: true)
    end

    def show
      @table_name = params[:id]
      @columns = fetch_table_columns(@table_name)
      @metadata = fetch_table_metadata(@table_name)
      @tables = fetch_tables_with_stats  # Fetch tables for sidebar

      set_pagination_params
      set_sorting_params

      # Extract column filters from params
      @column_filters = params[:column_filters].presence ? params[:column_filters].to_enum.to_h : {}

      if @column_filters.present? && @column_filters.values.any?(&:present?)
        @total_count = fetch_filtered_record_count(@table_name, @column_filters)
      else
        @total_count = fetch_table_record_count(@table_name)
      end

      @total_pages = calculate_total_pages(@total_count, @per_page)
      @records = fetch_table_records(@table_name)

      # Ensure @records is never nil to prevent template errors
      if @records.nil?
        column_names = fetch_table_columns(@table_name).map { |c| c[:name] }
        @records = ActiveRecord::Result.new(column_names, [])
      end

      # Fetch timestamp visualization data if the table has a created_at column
      if has_timestamp_column?(@table_name)
        @time_grouping = params[:time_group] || "daily"
        @timestamp_data = fetch_timestamp_data(@table_name, @time_grouping)
      end

      respond_to do |format|
        format.html # Default HTML response
        format.json do
          render json: {
            table_name: @table_name,
            columns: @columns,
            metadata: @metadata,
            record_count: @total_count
          }
        end
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
      unless Dbviewer.configuration.enable_data_export
        flash[:alert] = "Data export is disabled in the configuration"
        redirect_to table_path(params[:id])
        return
      end

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
