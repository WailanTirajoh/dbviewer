module Dbviewer
  class LogsController < ApplicationController
    before_action :set_filters, only: [ :index ]

    def index
      @queries = logger.recent_queries(
        limit: @limit,
        table_filter: @table_filter,
        request_id: @request_id,
        min_duration: @min_duration
      )

      if @request_id.present? || @table_filter.present? || @min_duration.present?
        @stats = logger.stats_for_queries(@queries)
        @filtered_stats = true
      else
        @stats = logger.stats
        @filtered_stats = false
      end
    end

    def destroy_all
      logger.clear
      flash[:success] = "Query logs cleared successfully"

      redirect_to logs_path
    end

    private

    def set_filters
      @table_filter = params[:table_filter]
      @request_id = params[:request_id]
      @min_duration = params[:min_duration]
      @limit = (params[:limit] || 100).to_i
      @limit = 1000 if @limit > 1000
    end

    def logger
      @logger ||= Dbviewer::Logger.instance
    end
  end
end
