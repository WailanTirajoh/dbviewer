module Dbviewer
  module Api
    class TablesController < BaseController
      def index
        tables = fetch_tables_with_stats(include_record_counts: false)
        render_success(total_tables: tables.size)
      end

      def records
        tables = fetch_tables_with_stats(include_record_counts: true)

        records_data = {
          total_records: tables.sum { |t| t[:record_count] },
          largest_tables: tables.sort_by { |t| -t[:record_count] }.first(10),
          empty_tables: tables.select { |t| t[:record_count] == 0 },
          avg_records_per_table: tables.any? ? (tables.sum { |t| t[:record_count] }.to_f / tables.size).round(1) : 0
        }

        render_success(records_data)
      end

      def relationships_count
        begin
          tables = fetch_tables_with_stats(include_record_counts: false)
          total_relationships = 0

          tables.each do |table|
            metadata = fetch_table_metadata(table[:name])
            total_relationships += metadata[:foreign_keys].size if metadata && metadata[:foreign_keys]
          end

          render_success(total_relationships: total_relationships)
        rescue => e
          render_error("Error calculating relationship count: #{e.message}")
        end
      end
    end
  end
end
