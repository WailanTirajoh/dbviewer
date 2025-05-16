module Dbviewer
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      # Ensure common database errors are handled gracefully
      rescue_from ActiveRecord::ActiveRecordError, with: :handle_database_error
    end

    # Handle database connection errors
    def handle_database_error(exception)
      message = case exception
      when ActiveRecord::ConnectionNotEstablished
        "Database connection could not be established."
      when ActiveRecord::StatementInvalid
        "Invalid SQL statement: #{exception.message}"
      else
        "Database error: #{exception.message}"
      end

      flash.now[:error] = message
      Rails.logger.error("Database error: #{exception.message}\n#{exception.backtrace.join("\n")}")

      # Determine where to redirect based on the current action
      if action_name == "show" || action_name == "query"
        @error = message
        @records = nil
        render action_name
      else
        @tables = []
        render :index
      end
    end

    def log_error(error, prefix = "Error")
      error_msg = "#{prefix}: #{error.message}"
      flash.now[:error] = error_msg
      Rails.logger.error("#{prefix}: #{error.message}\n#{error.backtrace.join("\n")}")
      error_msg
    end
  end
end
