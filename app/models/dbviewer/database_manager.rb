module Dbviewer
  class DatabaseManager
    attr_reader :connection, :adapter_name

    PER_PAGE = 20

    # Use a class-level callback mechanism with Ruby metaprogramming
    class << self
      def ensure_connection_for(*method_names)
        method_names.each do |method_name|
          # Only apply to methods that exist to avoid errors
          if instance_methods(false).include?(method_name)
            # Store the original method
            alias_method "#{method_name}_without_connection", method_name

            # Define a new method that ensures connection before calling the original
            define_method(method_name) do |*args, &block|
              ensure_connection
              send("#{method_name}_without_connection", *args, &block)
            end
          end
        end
      end

      def method_added(method_name)
        # Skip methods we've already processed or private/protected methods
        return if @_processing_method || private_method_defined?(method_name) || protected_method_defined?(method_name)

        # Prevent infinite recursion
        @_processing_method = true

        # Only process methods that aren't already ensure_connection-wrapped
        unless method_name.to_s.end_with?('_without_connection') || method_name == :initialize || method_name == :ensure_connection
          ensure_connection_for(method_name)
        end

        @_processing_method = false
      end
    end

    def initialize
      ensure_connection
    end

    def tables
      begin
        return [] unless connection.respond_to?(:tables)
        connection.tables.sort
      rescue => e
        log_error("Error fetching tables: #{e.message}", e)
        []
      end
    end

    def table_columns(table_name)
      begin
        return [] unless connection.respond_to?(:columns)

        connection.columns(table_name).map do |column|
          {
            name: column.name,
            type: column.type,
            null: column.null,
            default: column.default
          }
        end
      rescue => e
        log_error("Error fetching columns for table '#{table_name}': #{e.message}", e)
        []
      end
    end

    def table_count(table_name, search = {})
      begin
        where_clause, params = build_search_conditions(table_name, search)

        quoted_table = connection.quote_table_name(table_name)
        sql = "SELECT COUNT(*) AS count FROM #{quoted_table} #{where_clause}"

        result = connection.exec_query(sql, 'SQL', params)
        result.rows.first.first
      rescue => e
        log_error("Error counting records for table '#{table_name}': #{e.message}", e)
        0
      end
    end

    def table_records(table_name, page = 1, order_by = nil, direction = 'ASC', search = {})
      begin
        page = [1, page.to_i].max
        offset = (page - 1) * PER_PAGE

        # Sanitize order direction
        direction = %w[ASC DESC].include?(direction.to_s.upcase) ? direction.to_s.upcase : 'ASC'

        # Build order clause if order_by is provided
        order_clause = ""
        if order_by.present?
          quoted_order = connection.quote_column_name(order_by)
          order_clause = "ORDER BY #{quoted_order} #{direction}"
        end

        where_clause, params = build_search_conditions(table_name, search)
        quoted_table = connection.quote_table_name(table_name)

        sql = "SELECT * FROM #{quoted_table} #{where_clause} #{order_clause} LIMIT #{PER_PAGE} OFFSET #{offset}"

        connection.exec_query(sql, 'SQL', params)
      rescue => e
        log_error("Error fetching records for table '#{table_name}': #{e.message}", e)
        empty_result_set(table_name)
      end
    end

    def record_count(table_name)
      begin
        result = connection.exec_query(
          "SELECT COUNT(*) FROM #{connection.quote_table_name(table_name)}"
        )
        result.rows.first.first
      rescue => e
        log_error("Error counting records for table '#{table_name}': #{e.message}", e)
        0
      end
    end

    def column_count(table_name)
      begin
        connection.columns(table_name).size
      rescue => e
        log_error("Error counting columns for table '#{table_name}': #{e.message}", e)
        0
      end
    end

    def primary_key(table_name)
      begin
        connection.primary_key(table_name)
      rescue => e
        log_error("Error fetching primary key for table '#{table_name}': #{e.message}", e)
        nil
      end
    end

    def execute_query(sql)
      begin
        connection.exec_query(sql)
      rescue => e
        log_error("Error executing SQL query: #{e.message}", e)
        raise e
      end
    end

    private

    def ensure_connection
      return @connection if @connection

      unless defined?(ActiveRecord::Base)
        raise ConnectionError, "ActiveRecord is not available. This gem requires ActiveRecord to function."
      end

      begin
        @connection = ActiveRecord::Base.connection
        @adapter_name = @connection.adapter_name.downcase
        @connection
      rescue => e
        error_msg = "Failed to establish database connection: #{e.message}"
        log_error(error_msg, e)
        raise ConnectionError, error_msg
      end
    end

    # Define a custom error class
    class ConnectionError < StandardError; end

    def build_search_conditions(table_name, search)
      return ["", []] if search.blank?

      conditions = []
      params = []

      search.each do |column, value|
        next if value.blank?

        quoted_column = connection.quote_column_name(column)

        begin
          # Try to infer column type to handle properly
          column_info = table_columns(table_name).find { |c| c[:name].to_s == column.to_s }
          column_type = column_info ? column_info[:type] : :string

          # Use database-specific text search based on adapter
          if adapter_name =~ /postgres/
            case column_type
            when :integer, :decimal, :float, :bigint
              if value.to_s =~ /\A[0-9]+\z/ # pure number
                conditions << "#{quoted_column} = ?"
                params << value
              else
                # Handle ranges like 100-200
                if value.to_s =~ /\A(\d+)-(\d+)\z/
                  min, max = $1, $2
                  conditions << "(#{quoted_column} BETWEEN ? AND ?)"
                  params << min << max
                else
                  conditions << "CAST(#{quoted_column} AS TEXT) LIKE ?"
                  params << "%#{value}%"
                end
              end
            when :boolean
              if value.to_s.downcase == 'true' || value.to_s == '1'
                conditions << "#{quoted_column} = TRUE"
              elsif value.to_s.downcase == 'false' || value.to_s == '0'
                conditions << "#{quoted_column} = FALSE"
              else
                conditions << "CAST(#{quoted_column} AS TEXT) LIKE ?"
                params << "%#{value}%"
              end
            when :date, :datetime, :timestamp
              if value =~ /\A\d{4}-\d{2}-\d{2}/
                conditions << "CAST(#{quoted_column} AS TEXT) LIKE ?"
                params << "#{value}%"
              else
                conditions << "CAST(#{quoted_column} AS TEXT) LIKE ?"
                params << "%#{value}%"
              end
            else
              # String and other types - avoid the ::text cast as it can cause issues with certain column types
              # Instead use CAST explicitly which is safer
              conditions << "CAST(#{quoted_column} AS TEXT) ILIKE ?"
              params << "%#{value}%"
            end
          elsif adapter_name =~ /mysql/
            # MySQL - Use LIKE with case-insensitive collation
            conditions << "CONVERT(#{quoted_column} USING utf8) LIKE ?"
            params << "%#{value}%"
          elsif adapter_name =~ /sqlite/
            # SQLite - Use LIKE with built-in case insensitivity
            conditions << "#{quoted_column} LIKE ? COLLATE NOCASE"
            params << "%#{value}%"
          else
            # Default fallback for other adapters
            conditions << "CAST(#{quoted_column} AS VARCHAR) LIKE ?"
            params << "%#{value}%"
          end
        rescue => e
          # Fallback if anything goes wrong with the column type detection
          log_error("Search error: #{e.message}", e)

          if adapter_name =~ /postgres/
            # Use safer CAST instead of ::text
            conditions << "CAST(#{quoted_column} AS TEXT) ILIKE ?"
          else
            conditions << "CAST(#{quoted_column} AS VARCHAR) LIKE ?"
          end
          params << "%#{value}%"
        end
      end

      if conditions.any?
        ["WHERE #{conditions.join(' AND ')}", params]
      else
        ["", []]
      end
    end

    def log_error(message, error = nil)
      if defined?(Rails) && Rails.logger
        Rails.logger.error "DBViewer: #{message}"
        Rails.logger.error error.backtrace.join("\n") if error && error.backtrace
      else
        puts "DBViewer ERROR: #{message}"
      end
    end

    def empty_result_set(table_name)
      column_names = table_columns(table_name).map { |c| c[:name] }
      ActiveRecord::Result.new(column_names, [])
    end

    # We no longer need to manually register methods
    # The method_added callback automatically handles this for all public methods
    # (except initialize and ensure_connection)
  end
end
