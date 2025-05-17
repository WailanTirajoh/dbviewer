module Dbviewer
  class DatabasesController < ApplicationController
    # Include concerns for modular functionality
    include Dbviewer::DatabaseOperations
    include Dbviewer::PaginationConcern
    include Dbviewer::ErrorHandling

    # Action to show database analytics overview
    def index
      @tables = fetch_tables_with_stats
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

    # Action to display ERD (Entity Relationship Diagram)
    def erd
      # Ensure we have the necessary data for the ERD
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
    rescue => e
      @tables = []
      @table_relationships = []

      error_msg = log_error(e, "ERD generation error")

      respond_to do |format|
        format.html # Default to HTML view
        format.json do
          render json: { error: error_msg }, status: :unprocessable_entity
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
      rescue => e
        @records = []
        error_msg = log_error(e, "Table data error")

        respond_to do |format|
          format.html # Flash message already set in log_error
          format.json do
            render json: { error: error_msg }, status: :unprocessable_entity
          end
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
  end
end
