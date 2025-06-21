require "csv"

module Dbviewer
  module DatabaseOperations
    module DataExport
      extend ActiveSupport::Concern

      # Export table data to CSV
      def export_table_to_csv(table_name, query_params = nil, include_headers = true)
        records = database_manager.table_query_operations.table_records(table_name, query_params)

        CSV.generate do |csv|
          csv << records.columns if include_headers

          record_body = records.rows.map do |row|
            row.map { |cell| format_csv_value(cell) }
          end
          csv.concat(record_body)
        end
      end

      private

      # Format cell values for CSV export to handle nil values and special characters
      def format_csv_value(value)
        return "" if value.nil?
        value.to_s
      end
    end
  end
end
