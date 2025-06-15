module Dbviewer
  class TablesController < ApplicationController
    include Dbviewer::PaginationConcern

    before_action :set_table_name, except: [ :index ]
    before_action :set_query_filters, only: [ :show, :export_csv ]
    before_action :set_global_filters, only: [ :show, :export_csv ]

    def index
      @tables = fetch_tables(include_record_counts: true)
    end

    def show
      query_params = Dbviewer::Datatable::QueryParams.new(
        page: @current_page,
        per_page: @per_page,
        order_by: @order_by,
        direction: @order_direction,
        column_filters: @column_filters.reject { |_, v| v.blank? }
      )

      # Get all datatable data in one method call
      datatable_data = fetch_datatable_data(@table_name, query_params)

      # Assign to instance variables for view access
      @total_count = datatable_data[:total_count]
      @records = datatable_data[:records]
      @total_pages = datatable_data[:total_pages]
      @columns = datatable_data[:columns]
      @metadata = datatable_data[:metadata]

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
      @tables = fetch_tables  # Fetch tables for sidebar

      @query = prepare_query(@table_name, params[:query])
      @records = execute_query(@query)

      render :query
    end

    def export_csv
      unless Dbviewer.configuration.enable_data_export
        flash[:alert] = "Data export is disabled in the configuration"
        redirect_to table_path(params[:id])
        return
      end

      include_headers = params[:include_headers] != "0"
      query_params = Dbviewer::Datatable::QueryParams.new(
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
      @order_by = params[:order_by].presence || determine_default_order_column
      @order_direction = params[:order_direction].upcase if params[:order_direction].present?
      @order_direction = "DESC" unless self.class::VALID_SORT_DIRECTIONS.include?(@order_direction)
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

    # Determine the default order column using configurable ordering logic
    def determine_default_order_column
      # Get the table columns to check what's available
      columns = @columns || fetch_table_columns(@table_name)
      column_names = columns.map { |col| col[:name] }

      # Try the configured default order column first
      default_column = Dbviewer.configuration.default_order_column
      return default_column if default_column && column_names.include?(default_column)

      # Fall back to primary key
      primary_key = database_manager.primary_key(@table_name)
      return primary_key if primary_key.present?

      # Final fallback to first column
      columns.first ? columns.first[:name] : nil
    end
  end
end
