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

    def relationships
      # New action to fetch relationships asynchronously
      begin
        @table_relationships = fetch_table_relationships
        render json: {
          relationships: @table_relationships,
          status: "success"
        }
      rescue => e
        Rails.logger.error("[DBViewer] Error fetching relationships: #{e.message}")
        render json: {
          relationships: [],
          status: "error",
          error: e.message
        }, status: :internal_server_error
      end
    end

    def table_relationships
      # New action to fetch relationships for specific tables
      table_names = params[:tables]&.split(",") || []

      if table_names.blank?
        render json: {
          relationships: [],
          status: "error",
          error: "No tables specified"
        }, status: :bad_request
        return
      end

      begin
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

        render json: {
          relationships: relationships,
          status: "success",
          processed_tables: table_names
        }
      rescue => e
        Rails.logger.error("[DBViewer] Error in table_relationships: #{e.message}")
        render json: {
          relationships: [],
          status: "error",
          error: e.message
        }, status: :internal_server_error
      end
    end
  end
end
