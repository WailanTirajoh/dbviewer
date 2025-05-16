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
  end
end
