module Dbviewer
  class DatabasesController < ApplicationController
    PER_PAGE = 20

    def index
      begin
        @tables = fetch_database_tables.map do |table_name|
          {
            name: table_name,
            record_count: count_table_records(table_name),
            columns_count: count_table_columns(table_name)
          }
        end
      rescue => e
        Rails.logger.error "DBViewer Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        @tables = []
        flash.now[:error] = "Error loading database tables: #{e.message}"
      end
    end

    def show
      @table_name = params[:id]
      @columns = fetch_table_columns(@table_name)
      @current_page = (params[:page] || 1).to_i
      @order_by = params[:order_by] || primary_key_for(@table_name) || @columns.first[:name]
      @order_direction = params[:order_direction] || 'ASC'
      @total_count = fetch_table_count(@table_name)
      @total_pages = (@total_count.to_f / PER_PAGE).ceil
      @records = fetch_table_records(@table_name, @current_page, @order_by, @order_direction)
    end

    def query
      @table_name = params[:id]
      @query = params[:query].presence || "SELECT * FROM #{ActiveRecord::Base.connection.quote_table_name(@table_name)} LIMIT 100"

      begin
        @records = ActiveRecord::Base.connection.exec_query(@query)
        @error = nil
      rescue => e
        @records = nil
        @error = e.message
      end

      render :query
    end

    private

    def fetch_database_tables
      tables = []
      begin
        return [] unless defined?(ActiveRecord::Base)
        connection = ActiveRecord::Base.connection
        return [] unless connection.respond_to?(:tables)

        tables = connection.tables.sort
      rescue => e
        Rails.logger.error "DBViewer Error in fetch_database_tables: #{e.message}" if Rails.logger
        tables = []
      end
      tables
    end

    def count_table_records(table_name)
      result = ActiveRecord::Base.connection.exec_query(
        "SELECT COUNT(*) FROM #{ActiveRecord::Base.connection.quote_table_name(table_name)}"
      )
      result.rows.first.first
    rescue => e
      0
    end

    def count_table_columns(table_name)
      ActiveRecord::Base.connection.columns(table_name).size
    rescue => e
      0
    end

    def fetch_table_columns(table_name)
      begin
        return [] unless defined?(ActiveRecord::Base)
        connection = ActiveRecord::Base.connection
        return [] unless connection.respond_to?(:columns)

        connection.columns(table_name).map do |column|
          {
            name: column.name,
            type: column.type,
            null: column.null,
            default: column.default
          }
        end
      rescue => e
        Rails.logger.error "DBViewer Error in fetch_table_columns: #{e.message}" if Rails.logger
        []
      end
    end

    def primary_key_for(table_name)
      ActiveRecord::Base.connection.primary_key(table_name)
    rescue
      nil
    end

    def fetch_table_count(table_name)
      result = ActiveRecord::Base.connection.exec_query(
        "SELECT COUNT(*) AS count FROM #{ActiveRecord::Base.connection.quote_table_name(table_name)}"
      )
      result.rows.first.first
    end

    def fetch_table_records(table_name, page = 1, order_by = nil, direction = 'ASC')
      offset = (page - 1) * PER_PAGE
      order_clause = order_by ? "ORDER BY #{ActiveRecord::Base.connection.quote_column_name(order_by)} #{direction}" : ""

      ActiveRecord::Base.connection.exec_query(
        "SELECT * FROM #{ActiveRecord::Base.connection.quote_table_name(table_name)}
         #{order_clause}
         LIMIT #{PER_PAGE} OFFSET #{offset}"
      )
    end
  end
end
