module Dbviewer
  class DatabasesController < ApplicationController
    PER_PAGE = 20

    def index
      begin
        @tables = database_manager.tables.map do |table_name|
          {
            name: table_name,
            record_count: database_manager.record_count(table_name),
            columns_count: database_manager.column_count(table_name)
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

      begin
        @columns = database_manager.table_columns(@table_name)
        @current_page = (params[:page] || 1).to_i
        @order_by = params[:order_by] || database_manager.primary_key(@table_name) || (@columns.first ? @columns.first[:name] : nil)
        @order_direction = params[:order_direction] || 'ASC'
        @search = params[:search] || {}

        # Get count and records with search applied
        @total_count = database_manager.table_count(@table_name, @search)
        @total_pages = (@total_count.to_f / PER_PAGE).ceil
        @records = database_manager.table_records(@table_name, @current_page, @order_by, @order_direction, @search)
      rescue => e
        Rails.logger.error "Error in show action: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        @columns ||= []
        @records ||= nil
        @total_count ||= 0
        @total_pages ||= 0
        @search ||= {}
        flash.now[:error] = "Error displaying table: #{e.message}"
      end
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
