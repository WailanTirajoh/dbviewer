module Dbviewer
  class DatabaseManager
    attr_reader :connection, :adapter_name

    PER_PAGE = 20

    # Cache for dynamically created AR models
    @@dynamic_models = {}

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
      model = get_model_for(table_name)
      model.count
    end

    def table_records(table_name, page = 1, order_by = nil, direction = 'ASC')
      page = [1, page.to_i].max
      model = get_model_for(table_name)
      query = model.all

      # Apply sorting if provided
      if order_by.present?
        direction = %w[ASC DESC].include?(direction.to_s.upcase) ? direction.to_s.upcase : 'ASC'
        query = query.order("#{connection.quote_column_name(order_by)} #{direction}")
      end

      # Apply pagination
      records = query.limit(PER_PAGE).offset((page - 1) * PER_PAGE)

      # Transform the ActiveRecord::Relation to the format expected by the application
      to_result_set(records, table_name)
    end

    def record_count(table_name)
      get_model_for(table_name).count
    end

    def column_count(table_name)
      connection.columns(table_name).size
    end

    def primary_key(table_name)
      connection.primary_key(table_name)
    end

    def execute_query(sql)
      # For custom SQL queries, we still need to use exec_query
      # However, we add a warning log to encourage using AR methods instead
      Rails.logger.info("[DBViewer] Using raw SQL query: #{sql}") if defined?(Rails)
      connection.exec_query(sql)
    end    # A safer alternative to execute_query
    def query_table(table_name, select: nil, order: nil, limit: nil, offset: nil)
      model = get_model_for(table_name)
      query = model.all

      query = query.select(select) if select.present?
      query = query.order(order) if order.present?
      query = query.limit(limit) if limit.present?
      query = query.offset(offset) if offset.present?

      to_result_set(query, table_name)
    end

    private

    def ensure_connection
      return @connection if @connection

      @connection = ActiveRecord::Base.connection
      @adapter_name = @connection.adapter_name.downcase
      @connection
    end

    # Dynamically create an ActiveRecord model for a table
    def get_model_for(table_name)
      model_name = table_name.classify

      # Return cached model if available
      return @@dynamic_models[table_name] if @@dynamic_models[table_name]

      # Create a new model class dynamically
      model = Class.new(ActiveRecord::Base) do
        self.table_name = table_name

        # Some tables might not have primary keys, so we handle that
        begin
          primary_key = connection.primary_key(table_name)
          self.primary_key = primary_key if primary_key.present?
        rescue => e
          # If we can't determine the primary key, default to id or set to nil
          self.primary_key = 'id'
        end

        # Disable STI
        self.inheritance_column = :_type_disabled
      end

      # Set model name constant if not already taken
      unless Object.const_defined?(model_name)
        Object.const_set(model_name, model)
      end

      # Cache the model
      @@dynamic_models[table_name] = model
      model
    end

    # Convert ActiveRecord::Relation to the expected result format
    def to_result_set(records, table_name)
      column_names = connection.columns(table_name).map(&:name)
      rows = records.map do |record|
        column_names.map { |col| record[col] }
      end

      ActiveRecord::Result.new(column_names, rows)
    end
  end
end
