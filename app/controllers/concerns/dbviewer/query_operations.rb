module Dbviewer
  module QueryOperations
    extend ActiveSupport::Concern

    # Prepare the SQL query - either from params or default
    def prepare_query(table_name, query)
      query = query.present? ? query.to_s : default_query(table_name)

      # Validate query for security
      unless ::Dbviewer::Validator::Sql.safe_query?(query)
        query = default_query(table_name)
        flash.now[:warning] = "Only SELECT queries are allowed. Your query contained potentially unsafe operations. Using default query instead."
      end

      query
    end

    # Execute the prepared SQL query
    def execute_query(query)
      database_manager.execute_query(@query)
    end

    def default_query(table_name)
      quoted_table = safe_quote_table_name(table_name)
      "SELECT * FROM #{quoted_table} LIMIT 100"
    end
  end
end
