module Dbviewer
  module FormattingHelper
    def format_cell_value(value, table_name = nil, column_name = nil)
      # Apply PII masking if configured
      if table_name && column_name
        value = Dbviewer::DataPrivacy::PiiMasker.mask_value(value, table_name, column_name)
      end

      return "NULL" if value.nil?
      return format_default_value(value) unless value.is_a?(String)

      format_string_value(value)
    end

    private

    def format_string_value(value)
      case value
      when ->(v) { datetime_string?(v) }
        format_datetime_value(value)
      when ->(v) { date_string?(v) }
        format_date_value(value)
      when ->(v) { json_string?(v) }
        format_json_value(value)
      else
        format_default_value(value)
      end
    end

    def datetime_string?(value)
      value.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    def date_string?(value)
      value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    end

    def json_string?(value)
      value.match?(/\A{.+}\z/) || value.match?(/\A\[.+\]\z/)
    end

    def format_datetime_value(value)
      Time.parse(value).strftime("%Y-%m-%d %H:%M:%S")
    rescue
      format_default_value(value)
    end

    def format_date_value(value)
      value
    end

    def format_json_value(value)
      JSON.pretty_generate(JSON.parse(value)).truncate(100)
    rescue
      format_default_value(value)
    end

    def format_default_value(value)
      value.to_s.truncate(100)
    end
  end
end
