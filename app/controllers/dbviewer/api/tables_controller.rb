module Dbviewer
  module Api
    class TablesController < BaseController
      def index
        tables_count = fetch_tables_count
        render_success(total_tables: tables_count)
      end

      def records
        tables_stats = fetch_tables_stats
        render_success(tables_stats)
      end

      def relationships_count
        total_relationships = calculate_total_relationships
        render_success(total_relationships: total_relationships)
      end

      private

      def fetch_tables_count
        fetch_tables_with_stats(include_record_counts: false).size
      end

      def fetch_tables_stats
        tables = fetch_tables_with_stats(include_record_counts: true)

        {
          total_records: calculate_total_records(tables),
          largest_tables: find_largest_tables(tables),
          empty_tables: find_empty_tables(tables),
          avg_records_per_table: calculate_average_records(tables)
        }
      end

      def calculate_total_relationships
        tables = fetch_tables_with_stats(include_record_counts: false)

        tables.sum do |table|
          metadata = fetch_table_metadata(table[:name])
          metadata&.dig(:foreign_keys)&.size || 0
        end
      end

      def calculate_total_records(tables)
        tables.sum { |table| table[:record_count] }
      end

      def find_largest_tables(tables, limit = 10)
        tables.sort_by { |table| -table[:record_count] }.first(limit)
      end

      def find_empty_tables(tables)
        tables.select { |table| table[:record_count] == 0 }
      end

      def calculate_average_records(tables)
        return 0 if tables.empty?

        (calculate_total_records(tables).to_f / tables.size).round(1)
      end
    end
  end
end
