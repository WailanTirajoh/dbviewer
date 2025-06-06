module Dbviewer
  module RelationshipManagement
    extend ActiveSupport::Concern

    # Fetch relationships between tables for ERD visualization
    def fetch_table_relationships(tables)
      tables.flat_map { |table| extract_table_relationships_from_metadata(table[:name]) }
    end

    # Get mini ERD data for a specific table and its relationships
    def fetch_mini_erd_for_table(table_name)
      outgoing_data = collect_outgoing_relationships(table_name)
      incoming_data = collect_incoming_relationships(table_name)

      initial_tables = [ { name: table_name } ]
      all_relationships = outgoing_data[:relationships] + incoming_data[:relationships]
      all_tables = (initial_tables + outgoing_data[:tables] + incoming_data[:tables]).uniq { |t| t[:name] }

      {
        tables: all_tables,
        relationships: all_relationships,
        timestamp: Time.now.to_i
      }
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

    # Collect outgoing relationships from the specified table to other tables
    # @param table_name [String] The source table name
    # @return [Hash] Hash containing :tables and :relationships arrays
    def collect_outgoing_relationships(table_name)
      tables = []
      relationships = []

      metadata = fetch_table_metadata(table_name)
      return { tables: tables, relationships: relationships } unless metadata&.dig(:foreign_keys)&.present?

      metadata[:foreign_keys].each do |fk|
        result = process_outgoing_foreign_key(table_name, fk)
        if result
          relationships << result[:relationship]
          tables << result[:table]
        end
      end

      {
        tables: tables,
        relationships: relationships
      }
    end

    # Process a single outgoing foreign key relationship
    # @param table_name [String] The source table name
    # @param fk [Hash] Foreign key metadata
    # @return [Hash, nil] Hash containing :relationship and :table, or nil if invalid
    def process_outgoing_foreign_key(table_name, fk)
      return nil unless fk[:to_table].present? && fk[:column].present?

      relationship = build_relationship_hash(
        from_table: table_name.to_s,
        to_table: fk[:to_table].to_s,
        from_column: fk[:column].to_s,
        to_column: fk[:primary_key].to_s.presence || "id",
        name: fk[:name].to_s.presence || "#{table_name}_to_#{fk[:to_table]}",
        direction: "outgoing"
      )

      {
        relationship: relationship,
        table: {
          name: fk[:to_table].to_s
        }
      }
    end

    # Collect incoming relationships from other tables to the specified table
    # @param table_name [String] The target table name
    # @return [Hash] Hash containing :tables and :relationships arrays
    def collect_incoming_relationships(table_name)
      results = database_manager.tables
        .reject { |other_table_name| other_table_name == table_name }
        .map { |other_table_name| process_table_for_incoming_relationships(table_name, other_table_name) }
        .compact

      {
        tables: results.flat_map { |result| result[:tables] },
        relationships: results.flat_map { |result| result[:relationships] }
      }
    end

    # Process a single table to find incoming relationships to the target table
    # @param target_table [String] The target table name
    # @param source_table [String] The source table name to check
    # @return [Hash, nil] Hash containing :tables and :relationships arrays, or nil if no relationships
    def process_table_for_incoming_relationships(target_table, source_table)
      other_metadata = fetch_table_metadata(source_table)
      return nil unless other_metadata&.dig(:foreign_keys)&.present?

      results = other_metadata[:foreign_keys]
        .map { |fk| process_incoming_foreign_key(target_table, source_table, fk) }
        .compact

      return nil if results.empty?

      {
        tables: results.map { |result| result[:table] },
        relationships: results.map { |result| result[:relationship] }
      }
    end

    # Process a single incoming foreign key relationship
    # @param target_table [String] The target table name
    # @param source_table [String] The source table name
    # @param fk [Hash] Foreign key metadata
    # @return [Hash, nil] Hash containing :relationship and :table, or nil if invalid
    def process_incoming_foreign_key(target_table, source_table, fk)
      return nil unless fk[:to_table] == target_table && fk[:column].present?

      relationship = build_relationship_hash(
        from_table: source_table.to_s,
        to_table: target_table.to_s,
        from_column: fk[:column].to_s,
        to_column: fk[:primary_key].to_s.presence || "id",
        name: fk[:name].to_s.presence || "#{source_table}_to_#{target_table}",
        direction: "incoming"
      )

      {
        relationship: relationship,
        table: {
          name: source_table.to_s
        }
      }
    end

    # Build a standardized relationship hash
    # @param from_table [String] Source table name
    # @param to_table [String] Target table name
    # @param from_column [String] Source column name
    # @param to_column [String] Target column name
    # @param name [String] Relationship name
    # @param direction [String] Relationship direction
    # @return [Hash] Standardized relationship hash
    def build_relationship_hash(from_table:, to_table:, from_column:, to_column:, name:, direction:)
      {
        from_table: from_table,
        to_table: to_table,
        from_column: from_column,
        to_column: to_column,
        name: name,
        direction: direction
      }
    end
  end
end
