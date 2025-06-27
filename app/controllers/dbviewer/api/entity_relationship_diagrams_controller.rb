module Dbviewer
  module Api
    class EntityRelationshipDiagramsController < BaseController
      before_action :set_tables

      def relationships
        @table_relationships = fetch_table_relationships(@tables)
        render_success({
          relationships: @table_relationships,
          status: "success"
        })
      end

      def table_relationships
        table_names = params[:tables]&.split(",") || []

        relationships = table_names
          .filter { |table_name| @tables.any? { |t| t[:name] == table_name } }
          .flat_map { |table_name| extract_table_relationships(table_name) }

        render_success({
          relationships: relationships,
          status: "success",
          processed_tables: table_names
        })
      end

      private

      def set_tables
        @tables = fetch_tables
      end

      # Extract relationships for a single table, handling errors gracefully
      # @param table_name [String] The name of the table to process
      # @return [Array<Hash>] Array of relationship hashes for this table
      def extract_table_relationships(table_name)
        metadata = fetch_table_metadata(table_name)
        return [] unless metadata&.dig(:foreign_keys)&.present?
        table_names = @tables.map { |t| t[:name] }
        metadata[:foreign_keys].filter_map do |fk|
          # Only include relationship if target table is also accessible
          if table_names.include?(fk[:to_table])
            {
              from_table: table_name,
              to_table: fk[:to_table],
              from_column: fk[:column],
              to_column: fk[:primary_key],
              name: fk[:name]
            }
          end
        end
      rescue => e
        Rails.logger.error("[DBViewer] Error fetching relationships for #{table_name}: #{e.message}")
        [] # Return empty array to continue processing other tables
      end

      # Override to filter relationships to only accessible tables
      def fetch_table_relationships(tables)
        table_names = tables.map { |t| t[:name] }

        # Get all relationships from accessible tables
        all_relationships = super(tables)

        # Filter to only include relationships where both source and target tables are accessible
        all_relationships.select do |relationship|
          table_names.include?(relationship[:from_table]) &&
          table_names.include?(relationship[:to_table])
        end
      end
    end
  end
end
