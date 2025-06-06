module Dbviewer
  module DatatableSupport
    extend ActiveSupport::Concern

    # Consolidated method to fetch all datatable-related data in one call
    # Returns a hash containing all necessary datatable information
    def fetch_datatable_data(table_name, query_params)
      columns = fetch_table_columns(table_name)
      return default_datatable_structure(table_name) if columns.empty?

      if query_params.column_filters.empty?
        total_count = fetch_table_record_count(table_name)
      else
        total_count = fetch_filtered_record_count(table_name, query_params.column_filters)
      end

      {
        columns: columns,
        records: fetch_table_records(table_name, query_params),
        total_count: total_count,
        total_pages: total_count > 0 ? (total_count.to_f / query_params.per_page).ceil : 0,
        metadata: fetch_table_metadata(table_name),
        current_page: query_params.page,
        per_page: query_params.per_page,
        order_by: query_params.order_by,
        direction: query_params.direction
      }
    end

    private

    # Default structure for tables with no data/columns
    def default_datatable_structure(table_name)
      {
        columns: [],
        records: [],
        total_count: 0,
        total_pages: 0,
        metadata: {},
        current_page: 1,
        per_page: 25,
        order_by: nil,
        direction: "ASC"
      }
    end
  end
end
