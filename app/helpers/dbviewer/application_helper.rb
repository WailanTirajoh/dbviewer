module Dbviewer
  module ApplicationHelper
    def format_cell_value(value)
      return "NULL" if value.nil?
      return value.to_s.truncate(100) unless value.is_a?(String)

      case value
      when /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
        # ISO 8601 datetime
        begin
          Time.parse(value).strftime("%Y-%m-%d %H:%M:%S")
        rescue
          value.to_s.truncate(100)
        end
      when /\A\d{4}-\d{2}-\d{2}\z/
        # Date
        value
      when /\A{.+}\z/, /\A\[.+\]\z/
        # JSON
        begin
          JSON.pretty_generate(JSON.parse(value)).truncate(100)
        rescue
          value.to_s.truncate(100)
        end
      else
        value.to_s.truncate(100)
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
  end
end
