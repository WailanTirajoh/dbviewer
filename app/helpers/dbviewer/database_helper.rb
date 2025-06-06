module Dbviewer
  module DatabaseHelper
    # Check if a table has a created_at column
    def has_timestamp_column?(table_name)
      return false unless table_name.present?

      # Get the columns for the table directly using DatabaseManager
      columns = get_database_manager.table_columns(table_name)
      columns.any? { |col| col[:name] == "created_at" && [ :datetime, :timestamp ].include?(col[:type]) }
    end

    # Helper to access the database manager
    def get_database_manager
      @database_manager ||= ::Dbviewer::Database::Manager.new
    end

    # Extract column type from columns info
    def column_type_from_info(column_name, columns)
      return nil unless columns.present?

      column_info = columns.find { |c| c[:name].to_s == column_name.to_s }
      column_info ? column_info[:type].to_s.downcase : nil
    end

    # Get appropriate icon for column data type
    def column_type_icon(column_type)
      case column_type.to_s.downcase
      when /int/, /serial/, /number/, /decimal/, /float/, /double/
        "bi-123"
      when /char/, /text/, /string/, /uuid/
        "bi-fonts"
      when /date/, /time/
        "bi-calendar"
      when /bool/
        "bi-toggle-on"
      when /json/, /jsonb/
        "bi-braces"
      when /array/
        "bi-list-ol"
      else
        "bi-file-earmark"
      end
    end

    # Determine if the current table should be active in the sidebar
    def current_table?(table_name)
      @table_name.present? && @table_name == table_name
    end

    # Format table name for display - truncate if too long
    def format_table_name(table_name)
      if table_name.length > 20
        "#{table_name.first(17)}..."
      else
        table_name
      end
    end
  end
end
