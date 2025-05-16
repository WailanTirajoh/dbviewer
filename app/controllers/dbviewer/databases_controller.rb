module Dbviewer
  class DatabasesController < ApplicationController
    PER_PAGE = 20

    def index
      @tables = database_manager.tables.map do |table_name|
        {
          name: table_name,
          record_count: database_manager.record_count(table_name),
          columns_count: database_manager.column_count(table_name)
        }
      end
    end

    def show
      @table_name = params[:id]
      @columns = database_manager.table_columns(@table_name)
      @current_page = (params[:page] || 1).to_i
      @order_by = params[:order_by] || database_manager.primary_key(@table_name) || (@columns.first ? @columns.first[:name] : nil)
      @order_direction = params[:order_direction] || 'ASC'
      @total_count = database_manager.table_count(@table_name)
      @total_pages = (@total_count.to_f / PER_PAGE).ceil
      @records = database_manager.table_records(@table_name, @current_page, @order_by, @order_direction)
    end

    def query
      @table_name = params[:id]
      quoted_table = database_manager.connection.quote_table_name(@table_name) rescue @table_name
      @query = params[:query].presence || "SELECT * FROM #{quoted_table} LIMIT 100"

      begin
        @records = database_manager.execute_query(@query)
        @error = nil
      rescue => e
        @records = nil
        @error = e.message
      end

      render :query
    end

    private

    def database_manager
      @database_manager ||= DatabaseManager.new
    end
  end
end
