module Dbviewer
  class LogsController < ApplicationController
    before_action :set_filters, only: [ :index ]
    before_action :check_logging_enabled

    def index
      @queries = dbviewer_logger.recent_queries(
        limit: @limit,
        table_filter: @table_filter,
        request_id: @request_id,
        min_duration: @min_duration
      )

      if @request_id.present? || @table_filter.present? || @min_duration.present?
        @stats = dbviewer_logger.stats_for_queries(@queries)
        @filtered_stats = true
      else
        @stats = dbviewer_logger.stats
        @filtered_stats = false
      end
    end

    def destroy_all
      dbviewer_logger.clear
      flash[:success] = "Query logs cleared successfully"

      redirect_to logs_path
    end

    private

    def check_logging_enabled
      unless Dbviewer.configuration.enable_query_logging
        flash[:warning] = "Query logging is disabled. Enable it in the configuration to use this feature."
        redirect_to root_path
      end
    end

    def set_filters
      @table_filter = params[:table_filter]
      @request_id = params[:request_id]
      @min_duration = params[:min_duration]
      @limit = (params[:limit] || 100).to_i
      @limit = 1000 if @limit > 1000
    end

    def dbviewer_logger
      @dbviewer_logger ||= Dbviewer::Query::Logger.instance
    end
  end
end
