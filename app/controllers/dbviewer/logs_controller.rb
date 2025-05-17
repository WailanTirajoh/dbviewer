module Dbviewer
  class LogsController < ApplicationController
    include Dbviewer::ErrorHandling

    # Action to list all tables
    def index
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
        redirect_to logs_path and return
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
