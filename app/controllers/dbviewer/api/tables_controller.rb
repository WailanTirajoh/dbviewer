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

      def relationship_counts
        table_name = params[:id]
        record_id = params[:record_id]

        unless table_name.present? && record_id.present?
          render_error("Table name and record ID are required", 400)
          return
        end

        begin
          # Get table metadata to find relationships
          metadata = fetch_table_metadata(table_name)

          unless metadata
            render_error("Table not found", 404)
            return
          end

          # Get reverse foreign keys (has_many relationships)
          reverse_foreign_keys = metadata.dig(:reverse_foreign_keys) || []

          relationship_counts = reverse_foreign_keys.map do |rel|
            begin
              # Count records in the related table that reference this record
              count_query = "SELECT COUNT(*) as count FROM #{rel[:from_table]} WHERE #{rel[:column]} = ?"
              result = database_manager.connection.exec_query(count_query, "Count Query", [ record_id ])
              count = result.rows.first&.first || 0

              {
                table: rel[:from_table],
                foreign_key: rel[:column],
                count: count.to_i
              }
            rescue => e
              Rails.logger.error "Error counting relationships for #{rel[:from_table]}: #{e.message}"
              {
                table: rel[:from_table],
                foreign_key: rel[:column],
                count: 0,
                error: e.message
              }
            end
          end

          render_success({
            table_name: table_name,
            record_id: record_id,
            relationships: relationship_counts
          })
        rescue => e
          Rails.logger.error "Error fetching relationship counts: #{e.message}"
          render_error("Error fetching relationship counts: #{e.message}", 500)
        end
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
