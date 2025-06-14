module Dbviewer
  module DatatableUiFilterHelper
    # Determine default operator based on column type
    def default_operator_for_column_type(column_type)
      if column_type && column_type =~ /char|text|string|uuid|enum/i
        "contains"
      else
        "eq"
      end
    end

    # Generate operator options based on column type
    def operator_options_for_column_type(column_type)
      # Common operators for all types
      common_operators = [
        [ "is null", "is_null" ],
        [ "is not null", "is_not_null" ]
      ]

      type_specific_operators = if column_type && (column_type =~ /datetime/ || column_type =~ /^date$/ || column_type =~ /^time$/)
        # Date/Time operators
        [
          [ "=", "eq" ],
          [ "≠", "neq" ],
          [ "<", "lt" ],
          [ ">", "gt" ],
          [ "≤", "lte" ],
          [ "≥", "gte" ]
        ]
      elsif column_type && column_type =~ /int|float|decimal|double|number|numeric|real|money|bigint|smallint|tinyint|mediumint|bit/i
        # Numeric operators
        [
          [ "=", "eq" ],
          [ "≠", "neq" ],
          [ "<", "lt" ],
          [ ">", "gt" ],
          [ "≤", "lte" ],
          [ "≥", "gte" ]
        ]
      else
        # Text operators
        [
          [ "contains", "contains" ],
          [ "not contains", "not_contains" ],
          [ "=", "eq" ],
          [ "≠", "neq" ],
          [ "starts with", "starts_with" ],
          [ "ends with", "ends_with" ]
        ]
      end

      # Return type-specific operators first, then common operators
      type_specific_operators + common_operators
    end

    # Render column filter input based on column type
    def render_column_filter_input(form, column_name, column_type, column_filters)
      # Get selected operator to check if it's a null operator
      operator = column_filters["#{column_name}_operator"]
      is_null_operator = operator == "is_null" || operator == "is_not_null"

      # Clean up the value for non-null operators if the value contains a null operator
      # This ensures we don't carry over 'is_null' or 'is_not_null' values when switching operators
      value = column_filters[column_name]
      if !is_null_operator && value.present? && (value == "is_null" || value == "is_not_null")
        value = nil
      end

      # For null operators, display a non-editable field without placeholder
      if is_null_operator
        # Keep a hidden field for the actual value
        hidden_field = form.hidden_field("column_filters[#{column_name}]",
          value: operator,
          class: "null-filter-value",
          data: { column: column_name })

        # Add a visible but disabled text field with no placeholder or value
        visible_field = form.text_field("column_filters[#{column_name}_display]",
          disabled: true,
          value: "",
          class: "form-control form-control-sm column-filter border-end-1 border-start-0 rounded-0 disabled-filter",
          data: { column: "#{column_name}_display" })

        hidden_field + visible_field
      elsif column_type && column_type =~ /datetime/
        form.datetime_local_field("column_filters[#{column_name}]",
          value: value,
          class: "form-control form-control-sm column-filter border-end-1 border-start-0 rounded-0",
          data: { column: column_name })
      elsif column_type && column_type =~ /^date$/
        form.date_field("column_filters[#{column_name}]",
          value: value,
          class: "form-control form-control-sm column-filter border-end-1 border-start-0 rounded-0",
          data: { column: column_name })
      elsif column_type && column_type =~ /^time$/
        form.time_field("column_filters[#{column_name}]",
          value: value,
          class: "form-control form-control-sm column-filter border-end-1 border-start-0 rounded-0",
          data: { column: column_name })
      else
        form.text_field("column_filters[#{column_name}]",
          value: value,
          placeholder: "",
          class: "form-control form-control-sm column-filter border-end-1 border-start-0 rounded-0",
          data: { column: column_name })
      end
    end

    # Render operator select for column filter
    def render_operator_select(form, column_name, column_type, column_filters)
      # Get previously selected operator or default
      default_operator = default_operator_for_column_type(column_type)
      selected_operator = column_filters["#{column_name}_operator"]
      selected_operator = default_operator if selected_operator.nil? || selected_operator == "default"

      # Get appropriate options
      operator_options = operator_options_for_column_type(column_type)

      form.select("column_filters[#{column_name}_operator]",
        options_for_select(operator_options, selected_operator),
        { include_blank: false },
        { class: "form-select form-select-sm operator-select border-end-1 border-start-0 border-bottom-0" })
    end

    # Render complete filter input group for a column
    def render_column_filter(form, column_name, columns, column_filters)
      column_type = column_type_from_info(column_name, columns)

      content_tag(:div, class: "filter-input-group") do
        operator_select = render_operator_select(form, column_name, column_type, column_filters)
        input_field = render_column_filter_input(form, column_name, column_type, column_filters)

        operator_select + input_field
      end
    end
  end
end
