module Dbviewer
  class DatabasesController < ApplicationController
    # Sort direction validation
    VALID_SORT_DIRECTIONS = %w[ASC DESC].freeze

    # Use configuration values from Dbviewer module
    def self.per_page_options
      Dbviewer.configuration.per_page_options
    end

    def self.default_per_page
      Dbviewer.configuration.default_per_page
    end

    # Ensure common database errors are handled gracefully
    rescue_from ActiveRecord::ActiveRecordError, with: :handle_database_error

    # Action to list all available database tables
    def index
      @tables = fetch_tables_with_stats
    rescue => e
      @tables = []
      flash.now[:error] = "Error fetching database tables: #{e.message}"
      Rails.logger.error("Database tables fetch error: #{e.message}\n#{e.backtrace.join("\n")}")
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

      error_msg = "Error generating ERD: #{e.message}"
      flash.now[:error] = error_msg
      Rails.logger.error("ERD generation error: #{e.message}\n#{e.backtrace.join("\n")}")

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
        error_msg = "Error retrieving table data: #{e.message}"

        respond_to do |format|
          format.html do
            flash.now[:error] = error_msg
          end
          format.json do
            render json: { error: error_msg }, status: :unprocessable_entity
          end
        end

        Rails.logger.error("Table data error: #{e.message}\n#{e.backtrace.join("\n")}")
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

    private

    # Initialize the database manager
    def database_manager
      @database_manager ||= ::Dbviewer::DatabaseManager.new
    end

    # Fetch all tables with their record and column counts
    def fetch_tables_with_stats
      database_manager.tables.map do |table_name|
        {
          name: table_name,
          record_count: database_manager.record_count(table_name),
          columns_count: database_manager.column_count(table_name)
        }
      end
    end

    # Get column information for a specific table
    def fetch_table_columns(table_name)
      database_manager.table_columns(table_name)
    end

    # Set pagination parameters from request or defaults
    def set_pagination_params
      @current_page = [ 1, params[:page].to_i ].max
      @per_page = params[:per_page] ? params[:per_page].to_i : self.class.default_per_page
      @per_page = self.class.default_per_page unless self.class.per_page_options.include?(@per_page)
    end

    # Set sorting parameters from request or defaults
    def set_sorting_params
      @order_by = params[:order_by].presence ||
                  database_manager.primary_key(@table_name).presence ||
                  (@columns.first ? @columns.first[:name] : nil)

      @order_direction = params[:order_direction].upcase if params[:order_direction].present?
      @order_direction = "ASC" unless VALID_SORT_DIRECTIONS.include?(@order_direction)
    end

    # Get the total number of records in a table
    def fetch_table_record_count(table_name)
      database_manager.table_count(table_name)
    end

    # Calculate the total number of pages
    def calculate_total_pages(total_count, per_page)
      (total_count.to_f / per_page).ceil
    end

    # Fetch records for a table with pagination and sorting
    def fetch_table_records(table_name)
      database_manager.table_records(
        table_name,
        @current_page,
        @order_by,
        @order_direction,
        @per_page
      )
    end

    # Prepare the SQL query - either from params or default
    def prepare_query
      quoted_table = safe_quote_table_name(@table_name)
      default_query = "SELECT * FROM #{quoted_table} LIMIT 100"

      @query = params[:query].presence || default_query

      # Validate query for security
      unless ::Dbviewer::SqlValidator.safe_query?(@query)
        @query = default_query
        flash.now[:warning] = "Only SELECT queries are allowed. Your query contained potentially unsafe operations. Using default query instead."
      end
    end

    # Execute the prepared SQL query
    def execute_query
      begin
        @records = database_manager.execute_query(@query)
        @error = nil
      rescue => e
        @records = nil
        @error = e.message
        Rails.logger.error("SQL Query Error: #{e.message} for query: #{@query}")
      end
    end

    # Safely quote a table name, with fallback
    def safe_quote_table_name(table_name)
      database_manager.connection.quote_table_name(table_name)
    rescue => e
      Rails.logger.warn("Failed to quote table name: #{e.message}")
      table_name
    end

    # Get table metadata for display (e.g., primary key, foreign keys, indexes)
    def fetch_table_metadata(table_name)
      return {} unless database_manager.respond_to?(:table_metadata)

      begin
        database_manager.table_metadata(table_name)
      rescue => e
        Rails.logger.warn("Failed to fetch table metadata: #{e.message}")
        {}
      end
    end

    # Fetch relationships between tables for ERD visualization
    def fetch_table_relationships
      relationships = []

      @tables.each do |table|
        table_name = table[:name]

        # Get foreign keys defined in this table pointing to others
        begin
          metadata = database_manager.table_metadata(table_name)
          if metadata && metadata[:foreign_keys].present?
            metadata[:foreign_keys].each do |fk|
              relationships << {
                from_table: table_name,
                to_table: fk[:to_table],
                from_column: fk[:column],
                to_column: fk[:primary_key],
                name: fk[:name]
              }
            end
          end
        rescue => e
          Rails.logger.error("Error fetching relationships for #{table_name}: #{e.message}")
        end
      end

      relationships
    end

    # Handle database connection errors
    def handle_database_error(exception)
      message = case exception
      when ActiveRecord::ConnectionNotEstablished
        "Database connection could not be established."
      when ActiveRecord::StatementInvalid
        "Invalid SQL statement: #{exception.message}"
      else
        "Database error: #{exception.message}"
      end

      flash.now[:error] = message
      Rails.logger.error("Database error: #{exception.message}\n#{exception.backtrace.join("\n")}")

      # Determine where to redirect based on the current action
      if action_name == "show" || action_name == "query"
        @error = message
        @records = nil
        render action_name
      else
        @tables = []
        render :index
      end
    end
  end
end
