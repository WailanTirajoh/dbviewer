module Dbviewer
  module Api
    class QueriesController < BaseController
      def recent
        render_success({
          enabled: query_logging_enabled?,
          queries: fetch_recent_queries
        })
      end

      private

      def fetch_recent_queries
        return [] unless query_logging_enabled?

        Dbviewer::Query::Logger.instance.recent_queries(limit: queries_limit)
      end

      def query_logging_enabled?
        Dbviewer.configuration.enable_query_logging
      end

      def queries_limit
        10
      end
    end
  end
end
