module Dbviewer
  module DatabaseOperations
    module DatatableOperations
      extend ActiveSupport::Concern

      # Consolidated method to fetch all datatable-related data in one call
      # Returns a hash containing all necessary datatable information
      def fetch_datatable_data(table_name, query_params)
        columns = fetch_table_columns(table_name)

        total_count = fetch_table_record_count(table_name, query_params.column_filters)
        records = fetch_table_records(table_name, query_params)
        metadata = fetch_table_metadata(table_name)

        {
          columns: columns,
          records: records,
          total_count: total_count,
          total_pages: total_count > 0 ? (total_count.to_f / query_params.per_page).ceil : 0,
          metadata: metadata,
          current_page: query_params.page,
          per_page: query_params.per_page,
          order_by: query_params.order_by,
          direction: query_params.direction
        }
      end

      def fetch_table_stats(table_name)
        {
          table_name: table_name,
          columns: fetch_table_columns(table_name),
          metadata: fetch_table_metadata(table_name)
        }
      end
    end
  end
end
