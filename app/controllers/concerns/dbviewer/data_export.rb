require "csv"

module Dbviewer
  module DataExport
    extend ActiveSupport::Concern

    # Export table data to CSV
    def export_table_to_csv(table_name, query_params = nil, include_headers = true)
      records = database_manager.table_query_operations.table_records(table_name, query_params)

      csv_data = CSV.generate do |csv|
        # Add headers if requested
        csv << records.columns if include_headers

        # Add rows
        records.rows.each do |row|
          csv << row.map { |cell| format_csv_value(cell) }
        end
      end

      csv_data
    end

    private

    # Format cell values for CSV export to handle nil values and special characters
    def format_csv_value(value)
      return "" if value.nil?
      value.to_s
    end
  end
end
