module Dbviewer
  module Api
    class TablesController < BaseController
      def index
        render_success(total_tables: fetch_tables.length)
      end

      def show
        table_name = params[:id]

        # Check if table is accessible
        unless access_control.table_accessible?(table_name)
          render_error(access_control.access_violation_message(table_name), :forbidden)
          return
        end

        table_stats = fetch_table_stats(table_name)
        render_success(**table_stats)
      end

      def records
        all_tables_stats = fetch_tables_stats
        render_success(all_tables_stats)
      end

      def relationships_count
        total_relationships = calculate_total_relationships
        render_success(total_relationships: total_relationships)
      end

      def relationship_counts
        table_name = params[:id]
        record_id = params[:record_id]

        # Check if table is accessible
        unless access_control.table_accessible?(table_name)
          render_error("Access denied: Table '#{table_name}' is not accessible", :forbidden)
          return
        end

        reverse_foreign_keys = fetch_table_metadata(table_name).dig(:reverse_foreign_keys) || []
        relationship_counts = reverse_foreign_keys.map do |rel|
          # Only include relationships to accessible tables
          next unless access_control.table_accessible?(rel[:from_table])

          {
            table: rel[:from_table],
            foreign_key: rel[:column],
            count: database_manager.get_model_for(rel[:from_table]).where(rel[:column] => record_id).count
          }
        end.compact

        render_success({
          table_name: table_name,
          record_id: record_id,
          relationships: relationship_counts
        })
      end

      def mini_erd
        table_name = params[:id]
        erd_data = fetch_mini_erd_for_table(table_name)

        render_success(erd_data)
      end

      private

      def fetch_tables_count
        fetch_tables(include_record_counts: false).size
      end

      def fetch_tables_stats
        tables = fetch_tables(include_record_counts: true)

        {
          total_records: calculate_total_records(tables),
          largest_tables: find_largest_tables(tables),
          empty_tables: find_empty_tables(tables),
          avg_records_per_table: calculate_average_records(tables)
        }
      end

      def calculate_total_relationships
        tables = fetch_tables(include_record_counts: false)

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
