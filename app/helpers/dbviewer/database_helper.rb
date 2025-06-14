module Dbviewer
  module DatabaseHelper
    # Helper to access the database manager
    def get_database_manager
      @database_manager ||= ::Dbviewer::Database::Manager.new
    end

    # Check if a table has a created_at column
    def has_timestamp_column?(table_name)
      return false unless table_name.present?

      # Get the columns for the table directly using DatabaseManager
      columns = get_database_manager.table_columns(table_name)
      columns.any? { |col| col[:name] == "created_at" && [ :datetime, :timestamp ].include?(col[:type]) }
    end

    # Extract column type from columns info
    def column_type_from_info(column_name, columns)
      return nil unless columns.present?

      column_info = columns.find { |c| c[:name].to_s == column_name.to_s }
      column_info ? column_info[:type].to_s.downcase : nil
    end
  end
end
