module Dbviewer
  class EntityRelationshipDiagramsController < ApplicationController
    def index
      @tables = fetch_tables_with_stats

      if @tables.present?
        @table_relationships = fetch_table_relationships
      else
        @table_relationships = []
        flash.now[:warning] = "No tables found in database to generate ERD."
      end

      respond_to do |format|
        format.html # Default to HTML view
        format.json do
          render json: {
            tables: @tables,
            relationships: @table_relationships
          }
        end
      end
    end
  end
end
