module Dbviewer
  # ErrorHandler provides centralized error handling for database operations
  class ErrorHandler
    class << self
      # Execute a block with error handling
      # @param operation_name [String] Description of the operation for logging
      # @param default_return [Object] Value to return on error
      # @yield Block to execute
      # @return [Object] Result of block or default value on error
      def with_error_handling(operation_name, default_return = nil)
        yield
      rescue => e
        Rails.logger.error("[DBViewer] Error #{operation_name}: #{e.message}")
        default_return
      end
    end
  end
end
