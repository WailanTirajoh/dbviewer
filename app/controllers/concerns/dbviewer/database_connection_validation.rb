module Dbviewer
  module DatabaseConnectionValidation
    extend ActiveSupport::Concern

    included do
      before_action :validate_database_connection
    end

    private

    # Validate database connections on first access to DBViewer
    def validate_database_connection
      return if @database_validated

      begin
        connection_errors = Dbviewer.validate_connections!
        if connection_errors.any?
          Rails.logger.warn "DBViewer: Some database connections failed: #{connection_errors.map { |e| e[:error] }.join(', ')}"
        end
        @database_validated = true
      rescue => e
        render json: { error: "Database connection failed: #{e.message}" }, status: :service_unavailable and return
      end
    end
  end
end
