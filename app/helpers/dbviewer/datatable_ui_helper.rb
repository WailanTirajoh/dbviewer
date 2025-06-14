module Dbviewer
  module DatatableUiHelper
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

    # Format table name for display - truncate if too long
    def format_table_name(table_name)
      if table_name.length > 20
        "#{table_name.first(17)}..."
      else
        table_name
      end
    end

    # Determine if the current table should be active in the sidebar
    def current_table?(table_name)
      @table_name.present? && @table_name == table_name
    end
  end
end
