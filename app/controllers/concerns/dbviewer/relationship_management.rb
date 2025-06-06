module Dbviewer
  module RelationshipManagement
    extend ActiveSupport::Concern

    # Fetch relationships between tables for ERD visualization
    def fetch_table_relationships
      # Use functional approach: flat_map to extract all relationships from all tables
      @tables.flat_map do |table|
        extract_table_relationships_from_metadata(table[:name])
      end
    end

    # Get mini ERD data for a specific table and its relationships
    def fetch_mini_erd_for_table(table_name)
      related_tables = []
      relationships = []

      # Add current table
      related_tables << { name: table_name }

      # Get foreign keys from this table to others (outgoing relationships)
      begin
        metadata = fetch_table_metadata(table_name)
        Rails.logger.debug("[DBViewer] Table metadata: #{metadata.inspect}")

        if metadata && metadata[:foreign_keys].present?
          metadata[:foreign_keys].each do |fk|
            # Ensure all required fields are present
            next unless fk[:to_table].present? && fk[:column].present?

            # Sanitize table and column names for display
            from_table = table_name.to_s
            to_table = fk[:to_table].to_s
            from_column = fk[:column].to_s
            to_column = fk[:primary_key].to_s.presence || "id"
            relationship_name = fk[:name].to_s.presence || "#{from_table}_to_#{to_table}"

            relationship = {
              from_table: from_table,
              to_table: to_table,
              from_column: from_column,
              to_column: to_column,
              name: relationship_name,
              direction: "outgoing"
            }

            relationships << relationship
            Rails.logger.debug("[DBViewer] Added outgoing relationship: #{relationship.inspect}")

            # Add the related table if not already included
            unless related_tables.any? { |t| t[:name] == to_table }
              related_tables << { name: to_table }
            end
          end
        end
      rescue => e
        Rails.logger.error("[DBViewer] Error fetching outgoing relationships for #{table_name}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end

      # Get foreign keys from other tables to this one (incoming relationships)
      begin
        database_manager.tables.each do |other_table_name|
          next if other_table_name == table_name # Skip self

          begin
            other_metadata = fetch_table_metadata(other_table_name)
            if other_metadata && other_metadata[:foreign_keys].present?
              other_metadata[:foreign_keys].each do |fk|
                if fk[:to_table] == table_name
                  # Ensure all required fields are present
                  next unless fk[:column].present?

                  # Sanitize table and column names for display
                  from_table = other_table_name.to_s
                  to_table = table_name.to_s
                  from_column = fk[:column].to_s
                  to_column = fk[:primary_key].to_s.presence || "id"
                  relationship_name = fk[:name].to_s.presence || "#{from_table}_to_#{to_table}"

                  relationship = {
                    from_table: from_table,
                    to_table: to_table,
                    from_column: from_column,
                    to_column: to_column,
                    name: relationship_name,
                    direction: "incoming"
                  }

                  relationships << relationship
                  Rails.logger.debug("[DBViewer] Added incoming relationship: #{relationship.inspect}")

                  # Add the related table if not already included
                  unless related_tables.any? { |t| t[:name] == from_table }
                    related_tables << { name: from_table }
                  end
                end
              end
            end
          rescue => e
            Rails.logger.error("[DBViewer] Error processing relationships for table #{other_table_name}: #{e.message}")
            # Continue to the next table
          end
        end
      rescue => e
        Rails.logger.error("[DBViewer] Error fetching incoming relationships for #{table_name}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end

      # If no relationships were found, make sure to still include at least the current table
      if relationships.empty?
        Rails.logger.info("[DBViewer] No relationships found for table: #{table_name}")
      end

      result = {
        tables: related_tables,
        relationships: relationships,
        timestamp: Time.now.to_i
      }

      Rails.logger.info("[DBViewer] Mini ERD data generated: #{related_tables.length} tables, #{relationships.length} relationships")
      result
    end

    private

    # Extract relationships for a single table from its metadata
    # @param table_name [String] The name of the table to process
    # @return [Array<Hash>] Array of relationship hashes for this table
    def extract_table_relationships_from_metadata(table_name)
      metadata = database_manager.table_metadata(table_name)
      return [] unless metadata&.dig(:foreign_keys)&.present?

      metadata[:foreign_keys].map do |fk|
        {
          from_table: table_name,
          to_table: fk[:to_table],
          from_column: fk[:column],
          to_column: fk[:primary_key],
          name: fk[:name]
        }
      end
    end
  end
end
