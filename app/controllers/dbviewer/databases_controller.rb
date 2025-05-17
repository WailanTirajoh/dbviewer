module Dbviewer
  class DatabasesController < ApplicationController
    # Include concerns for modular functionality
    include Dbviewer::DatabaseOperations
    include Dbviewer::PaginationConcern
    include Dbviewer::ErrorHandling

    # Action to list all tables
    def index
      @tables = fetch_tables_with_stats
    end

    # Action to display ERD (Entity Relationship Diagram)
    def erd
      @tables = fetch_tables_with_stats

      if @tables.present?
        @table_relationships = fetch_table_relationships
      else
        @table_relationships = []
        flash.now[:warning] = "No tables found in database to generate ERD."
      end

      respond_to do |format|
        format.html # Default to HTML view
        format.json do
          render json: {
            tables: @tables,
            relationships: @table_relationships
          }
        end
      end
    end

    # Action to show details and records for a specific table
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

    # Action to execute custom SQL queries
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

    # Action to export table data to CSV
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

    # Action to display SQL query logs
    def logs
      require_dependency "dbviewer/logger"

      # Get filter parameters
      @table_filter = params[:table_filter]
      @request_id = params[:request_id]
      @min_duration = params[:min_duration]
      @limit = (params[:limit] || 100).to_i
      @limit = 1000 if @limit > 1000 # Cap at 1000 for performance

      # Clear logs if requested
      if params[:clear_logs] == "true"
        Dbviewer::Logger.instance.clear
        flash[:success] = "Query logs cleared successfully"
        redirect_to logs_databases_path and return
      end

      # Get query logs with optional filtering
      @queries = Dbviewer::Logger.instance.recent_queries(
        limit: @limit,
        table_filter: @table_filter,
        request_id: @request_id,
        min_duration: @min_duration
      )

      # Get query stats - if filtering is applied, only use stats from the filtered queries
      if @request_id.present? || @table_filter.present? || @min_duration.present?
        @stats = Dbviewer::Logger.instance.stats_for_queries(@queries)
        @filtered_stats = true
      else
        @stats = Dbviewer::Logger.instance.stats
        @filtered_stats = false
      end

      # Prepare tables list for sidebar
      @tables = fetch_tables_with_stats

      respond_to do |format|
        format.html # render logs.html.erb
        format.json { render json: { queries: @queries, stats: @stats } }
      end
    end
  end
end
