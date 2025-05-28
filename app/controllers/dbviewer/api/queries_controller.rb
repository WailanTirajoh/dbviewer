module Dbviewer
  module Api
    class QueriesController < BaseController
      def recent
        @recent_queries = if Dbviewer.configuration.enable_query_logging
          Dbviewer::Logger.instance.recent_queries(limit: 10)
        else
          []
        end

        render_success({
          enabled: Dbviewer.configuration.enable_query_logging,
          queries: @recent_queries
        })
      end
    end
  end
end
