module Dbviewer
  class Initializer
    class << self
      def setup
        if defined?(ActiveRecord::Base)
          Rails.logger.warn "ActiveRecord is not available, skipping database connection check"
          return
        end

        ensure_activerecord_connection
      end

      private

      def ensure_activerecord_connection
        ActiveRecord::Base.connection
        Rails.logger.info "DBViewer successfully connected to database"
      rescue => e
        Rails.logger.error "DBViewer could not connect to database: #{e.message}"
      end
    end
  end
end
