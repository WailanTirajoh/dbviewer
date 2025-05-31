module Dbviewer
  module Api
    class EntityRelationshipDiagramsController < BaseController
      before_action :set_tables

      def relationships
        @table_relationships = fetch_table_relationships
        render_success({
          relationships: @table_relationships,
          status: "success"
        })
      end

      def table_relationships
        table_names = params[:tables]&.split(",") || []
        relationships = []

        table_names.each do |table_name|
          next unless @tables.any? { |t| t[:name] == table_name }

          begin
            metadata = fetch_table_metadata(table_name)
            if metadata && metadata[:foreign_keys].present?
              metadata[:foreign_keys].each do |fk|
                relationships << {
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
            # Continue with other tables even if one fails
          end
        end

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
    end
  end
end
