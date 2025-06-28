module Dbviewer
  module DatabaseOperations
    module QueryOperations
      extend ActiveSupport::Concern

      # Prepare the SQL query - either from params or default
      def prepare_query(table_name, query)
        # Sanitize and validate input
        sanitized_query = sanitize_query_input(query)
        final_query = sanitized_query.present? ? sanitized_query.to_s : default_query(table_name)

        # Validate query for security
        unless ::Dbviewer::Validator::Sql.safe_query?(final_query)
          log_unsafe_query_attempt(final_query)
          final_query = default_query(table_name)
          flash.now[:warning] = "Only SELECT queries are allowed. Your query contained potentially unsafe operations. Using default query instead."
        end

        final_query
      end

      # Execute the prepared SQL query
      def execute_query(query)
        database_manager.execute_query(query)
      end

      def default_query(table_name)
        quoted_table = safe_quote_table_name(table_name)
        "SELECT * FROM #{quoted_table} LIMIT 100"
      end

      private

      # Safely quote a table name, with fallback
      def safe_quote_table_name(table_name)
        database_manager.connection.quote_table_name(table_name) rescue table_name.to_s
      end

      # Sanitize query input to prevent basic injection attempts
      def sanitize_query_input(query)
        return nil if query.nil?
        
        # Convert to string and strip whitespace
        sanitized = query.to_s.strip
        
        # Remove any null bytes that could be used to bypass security
        sanitized = sanitized.gsub(/\x00/, '')
        
        # Limit the query length as an additional safety measure
        max_length = 10000
        sanitized = sanitized.truncate(max_length) if sanitized.length > max_length
        
        sanitized
      end

      # Log unsafe query attempts for security monitoring
      def log_unsafe_query_attempt(query)
        Rails.logger.warn("[DBViewer][Security] Unsafe query blocked: #{query.truncate(200)}") if defined?(Rails)
        
        # Log to security monitoring system if available
        if defined?(::Dbviewer::Query::Logger)
          ::Dbviewer::Query::Logger.log_security_event(
            event_type: "unsafe_query_blocked",
            query_type: "user_query",
            sql: query,
            timestamp: Time.current
          )
        end
      rescue => e
        # Don't let logging errors break the application
        puts "[DBViewer] Security logging error: #{e.message}"
      end
    end
  end
end
