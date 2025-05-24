module Dbviewer
  class TablesController < ApplicationController
    include Dbviewer::PaginationConcern

    before_action :set_table_name, except: [ :index ]
    before_action :set_query_filters, only: [ :show, :export_csv ]
    before_action :set_global_filters, only: [ :show, :export_csv ]

    def index
      @tables = fetch_tables_with_stats(include_record_counts: true)
    end

    def show
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
        column_names = @columns.map { |column| column[:name] }
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
      @erd_data = fetch_mini_erd_for_table(@table_name)

      respond_to do |format|
        format.json { render json: @erd_data }
        format.html { render layout: false }
      end
    end

    def query
      @read_only_mode = true # Flag to indicate we're in read-only mode
      @columns = fetch_table_columns(@table_name)
      @tables = fetch_tables_with_stats  # Fetch tables for sidebar

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

      include_headers = params[:include_headers] != "0"
      query_params = Dbviewer::TableQueryParams.new(
        page: @current_page,
        per_page: (params[:limit] || 10000).to_i,
        order_by: @order_by,
        direction: @order_direction,
        column_filters: @column_filters.reject { |_, v| v.blank? }
      )
      csv_data = export_table_to_csv(@table_name, query_params, include_headers)

      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      filename = "#{@table_name}_#{timestamp}.csv"

      send_data csv_data,
                type: "text/csv; charset=utf-8; header=present",
                disposition: "attachment; filename=#{filename}"
    end

    private

    def set_table_name
      @table_name = params[:id]
    end

    def set_query_filters
      @current_page = [ 1, params[:page].to_i ].max
      @per_page = params[:per_page] ? params[:per_page].to_i : self.class.default_per_page
      @per_page = self.class.default_per_page unless self.class.per_page_options.include?(@per_page)
      @order_by = params[:order_by].presence ||
                  database_manager.primary_key(@table_name).presence ||
                  (@columns.first ? @columns.first[:name] : nil)
      @order_direction = params[:order_direction].upcase if params[:order_direction].present?
      @order_direction = "ASC" unless self.class::VALID_SORT_DIRECTIONS.include?(@order_direction)
      @column_filters = params[:column_filters].presence ? params[:column_filters].to_enum.to_h : {}
    end

    def set_global_filters
      # Store creation filter datetimes in session to persist between table navigation
      if params[:creation_filter_start].present?
        session[:creation_filter_start] = params[:creation_filter_start]
      end

      if params[:creation_filter_end].present?
        session[:creation_filter_end] = params[:creation_filter_end]
      end

      # Clear filters if explicitly requested
      if params[:clear_creation_filter] == "true"
        session.delete(:creation_filter_start)
        session.delete(:creation_filter_end)
      end

      # Set instance variables for view access
      @creation_filter_start = session[:creation_filter_start]
      @creation_filter_end = session[:creation_filter_end]

      # Initialize column_filters if not present
      @column_filters ||= {}

      # Apply creation filters to column_filters if the table has a created_at column
      if has_timestamp_column?(@table_name) && (@creation_filter_start.present? || @creation_filter_end.present?)
        # Clear any existing created_at filters
        %w[created_at created_at_operator created_at_end].each { |key| @column_filters.delete(key) }

        case
        when @creation_filter_start.present? && @creation_filter_end.present?
          @column_filters.merge!({
            "created_at" => @creation_filter_start,
            "created_at_end" => @creation_filter_end
          })
        when @creation_filter_start.present?
          @column_filters.merge!({
            "created_at" => @creation_filter_start,
            "created_at_operator" => "gte"
          })
        when @creation_filter_end.present?
          @column_filters.merge!({
            "created_at" => @creation_filter_end,
            "created_at_operator" => "lte"
          })
        end
      end
    end
  end
end
