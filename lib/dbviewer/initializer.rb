module Dbviewer
  class Initializer
    class << self
      def setup
        log "Initializing DBViewer engine..."
        if defined?(ActiveRecord::Base)
          ensure_activerecord_connection
        else
          log "ActiveRecord is not available, skipping database connection check"
        end
      end

      private

      def ensure_activerecord_connection
        return unless defined?(ActiveRecord::Base)

        begin
          ActiveRecord::Base.connection
          log "DBViewer successfully connected to database"
        rescue => e
          log "DBViewer could not connect to database: #{e.message}", :error
        end
      end

      def log(message, level = :info)
        if defined?(Rails) && Rails.logger
          Rails.logger.send(level, message)
        else
          puts "[DBViewer] #{level.upcase}: #{message}"
        end
      end
    end
  end
end
