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

    # Action to show details and records for a specific table
    def show
      @table_name = params[:id]
      @columns = fetch_table_columns(@table_name)
      @metadata = fetch_table_metadata(@table_name)

      set_pagination_params
      set_sorting_params

      @total_count = fetch_table_record_count(@table_name)
      @total_pages = calculate_total_pages(@total_count, @per_page)
      @records = fetch_table_records(@table_name)
    end

    # Action to execute custom SQL queries
    def query
      @table_name = params[:id]
      @read_only_mode = true # Flag to indicate we're in read-only mode
      @columns = fetch_table_columns(@table_name)

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
      @current_page = [1, params[:page].to_i].max
      @per_page = params[:per_page] ? params[:per_page].to_i : self.class.default_per_page
      @per_page = self.class.default_per_page unless self.class.per_page_options.include?(@per_page)
    end

    # Set sorting parameters from request or defaults
    def set_sorting_params
      @order_by = params[:order_by].presence ||
                  database_manager.primary_key(@table_name).presence ||
                  (@columns.first ? @columns.first[:name] : nil)

      @order_direction = params[:order_direction].upcase if params[:order_direction].present?
      @order_direction = 'ASC' unless VALID_SORT_DIRECTIONS.include?(@order_direction)
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
      if action_name == 'show' || action_name == 'query'
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
