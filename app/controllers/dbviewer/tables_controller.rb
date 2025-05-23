module Dbviewer
  class TablesController < ApplicationController
    include Dbviewer::PaginationConcern

    before_action :set_table_name, except: [ :index ]

    def index
      @tables = fetch_tables_with_stats(include_record_counts: true)
    end

    def show
      set_pagination_params
      set_sorting_params

      @column_filters = params[:column_filters].presence ? params[:column_filters].to_enum.to_h : {}
      query_params = Dbviewer::TableQueryParams.new(
        page: @current_page,
        per_page: @per_page,
        order_by: @order_by,
        direction: @order_direction,
        column_filters: @column_filters.reject { |_, v| v.blank? }
      )
      @total_count = fetch_total_count(@table_name, query_params)
      @records = fetch_table_records(@table_name, query_params)
      @total_pages = calculate_total_pages(@total_count, @per_page)
      @columns = fetch_table_columns(@table_name)
      @metadata = fetch_table_metadata(@table_name)

      if @records.nil?
        column_names = @columns.map { |c| c[:name] }
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

    def mini_erd
      begin
        @erd_data = fetch_mini_erd_for_table(@table_name)

        if @erd_data[:error].present?
          Rails.logger.error("Mini ERD error: #{@erd_data[:error]}")
        end

        respond_to do |format|
          format.json { render json: @erd_data }
          format.html { render layout: false }
        end
      rescue => e
        Rails.logger.error("Error generating Mini ERD: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))

        @error_message = e.message
        @erd_data = { tables: [], relationships: [], error: @error_message }

        respond_to do |format|
          format.json { render json: { error: @error_message }, status: :internal_server_error }
          format.html { render layout: false }
        end
      end
    end

    def query
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

      limit = (params[:limit] || 10000).to_i
      include_headers = params[:include_headers] != "0"

      csv_data = export_table_to_csv(@table_name, limit, include_headers)

      # Set filename with timestamp for uniqueness
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      filename = "#{@table_name}_export_#{timestamp}.csv"

      # Send data as file
      send_data csv_data,
                type: "text/csv; charset=utf-8; header=present",
                disposition: "attachment; filename=#{filename}"
    end

    private

    def set_table_name
      @table_name = params[:id]
    end
  end
end
