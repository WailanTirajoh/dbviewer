module Dbviewer
  class DatabaseManager
    attr_reader :connection, :adapter_name

    PER_PAGE = 20

    def initialize
      ensure_connection
    end

    def tables
      return [] unless connection.respond_to?(:tables)
      connection.tables.sort
    end

    def table_columns(table_name)
      connection.columns(table_name).map do |column|
        {
          name: column.name,
          type: column.type,
          null: column.null,
          default: column.default
        }
      end
    end

    def table_count(table_name)
      quoted_table = connection.quote_table_name(table_name)
      sql = "SELECT COUNT(*) AS count FROM #{quoted_table}"

      result = connection.exec_query(sql, 'SQL')
      result.rows.first.first
    end

    def table_records(table_name, page = 1, order_by = nil, direction = 'ASC', search = {})
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

      quoted_table = connection.quote_table_name(table_name)

      sql = "SELECT * FROM #{quoted_table} #{order_clause} LIMIT #{PER_PAGE} OFFSET #{offset}"

      connection.exec_query(sql, 'SQL')
    end

    def record_count(table_name)
      result = connection.exec_query(
        "SELECT COUNT(*) FROM #{connection.quote_table_name(table_name)}"
      )
      result.rows.first.first
    end

    def column_count(table_name)
      connection.columns(table_name).size
    end

    def primary_key(table_name)
      connection.primary_key(table_name)
    end

    def execute_query(sql)
      connection.exec_query(sql)
    end

    private

    def ensure_connection
      return @connection if @connection

      @connection = ActiveRecord::Base.connection
      @adapter_name = @connection.adapter_name.downcase
      @connection
    end
  end
end
