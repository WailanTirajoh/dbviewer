module Dbviewer
  class EntityRelationshipDiagramsController < ApplicationController
    def index
      # Only show warning if no tables exist, but don't fetch relationships on initial load
      if @tables.blank?
        flash.now[:warning] = "No tables found in database to generate ERD."
      end

      respond_to do |format|
        format.html # Just render the HTML without relationships
        format.json do
          # For JSON requests, return just tables initially
          render json: {
            tables: @tables,
            relationships: []
          }
        end
      end
    end
  end
end
