module Dbviewer
  module DatatableUiFormHelper
    def determine_field_type(column_type)
      case column_type
      when :boolean
        :check_box
      when :text
        :text_area
      when :date
        :date_field
      when :datetime, :timestamp
        :datetime_local_field
      else
        :text_field
      end
    end
  end
end
