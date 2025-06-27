module Dbviewer
  module DatatableUiTableHelper
    # Render a complete table header row with sortable columns
    def render_sortable_header_row(records, order_by, order_direction, table_name, current_page, per_page, column_filters)
      return content_tag(:tr) { content_tag(:th, "No columns available") } unless records&.columns

      content_tag(:tr) do
        # Start with action column header (sticky first column)
        headers = [
          content_tag(:th, class: "px-3 py-2 text-center action-column action-column-header border-bottom-0", width: "60px", rowspan: 2) do
            content_tag(:span, "Actions")
          end
        ]

        # Add all data columns
        headers += records.columns.map do |column_name|
          is_sorted = order_by == column_name
          content_tag(:th, class: "px-3 py-2 sortable-column border-bottom-0 #{is_sorted ? 'sorted' : ''}") do
            sortable_column_header(column_name, order_by, order_direction, table_name, current_page, per_page, column_filters)
          end
        end

        headers.join.html_safe
      end
    end

    # Render the column filters row
    def render_column_filters_row(form, records, columns, column_filters)
      return content_tag(:tr) { content_tag(:th, "") } unless records&.columns

      content_tag(:tr, class: "column-filters") do
        filters = records.columns.map do |column_name|
          content_tag(:th, class: "p-0 border-bottom-0") do
            render_column_filter(form, column_name, columns, column_filters)
          end
        end

        filters.join.html_safe
      end
    end

    # Render a cell that may include a foreign key link
    def render_table_cell(cell, column_name, metadata, table_name = nil)
      cell_value = format_cell_value(cell, table_name, column_name)
      foreign_key = metadata && metadata[:foreign_keys] ?
                    metadata[:foreign_keys].find { |fk| fk[:column] == column_name } :
                    nil

      if foreign_key && !cell.nil?
        fk_params = { column_filters: { foreign_key[:primary_key] => cell } }
        fk_params = fk_params.merge(common_params.except(:column_filters))

        content_tag(:td, title: "#{cell_value} (Click to view referenced record)") do
          link_to(cell_value, table_path(foreign_key[:to_table], fk_params),
                  class: "text-decoration-none foreign-key-link") +
          content_tag(:i, "", class: "bi bi-link-45deg text-muted small")
        end
      else
        content_tag(:td, cell_value, title: cell_value)
      end
    end

    # Render a table row with cells
    def render_table_row(row, records, metadata, table_name = nil)
      content_tag(:tr) do
        # Start with action column (sticky first column)
        cells = [ render_action_cell(row, records.columns, metadata, table_name) ]

        # Add all data cells
        cells += row.each_with_index.map do |cell, cell_index|
          column_name = records.columns[cell_index]
          render_table_cell(cell, column_name, metadata, table_name)
        end

        cells.join.html_safe
      end
    end

    # Render the entire table body with rows
    def render_table_body(records, metadata, table_name = nil)
      if records.nil? || records.rows.nil? || records.empty?
        content_tag(:tbody) do
          content_tag(:tr) do
            # Adding +1 to account for the action column
            total_columns = records&.columns&.size.to_i + 1
            content_tag(:td, "No records found or table is empty.", colspan: total_columns, class: "text-center")
          end
        end
      else
        content_tag(:tbody) do
          records.rows.map do |row|
            render_table_row(row, records, metadata, table_name)
          end.join.html_safe
        end
      end
    end

    # Render action buttons for a record
    def render_action_cell(row_data, columns, metadata = nil, table_name = nil)
      data_attributes = {}

      # Create a hash of column_name: value pairs for data attributes
      # Apply the same formatting logic used in table cells
      columns.each_with_index do |column_name, index|
        data_attributes[column_name] = format_cell_value(row_data[index], table_name, column_name)
      end

      content_tag(:td, class: "text-center action-column") do
        content_tag(:div, class: "d-flex gap-1 justify-content-center") do
          # View Record button (existing)
          view_button = button_tag(
            type: "button",
            class: "btn btn-sm btn-primary view-record-btn",
            title: "View Record Details",
            data: {
              bs_toggle: "modal",
              bs_target: "#recordDetailModal",
              record_data: data_attributes.to_json,
              foreign_keys: metadata && metadata[:foreign_keys] ? metadata[:foreign_keys].to_json : "[]",
              reverse_foreign_keys: metadata && metadata[:reverse_foreign_keys] ? metadata[:reverse_foreign_keys].to_json : "[]"
            }
          ) do
            content_tag(:i, "", class: "bi bi-eye")
          end

          # Copy FactoryBot button (new)
          copy_factory_button = button_tag(
            type: "button",
            class: "btn btn-sm btn-outline-secondary copy-factory-btn",
            title: "Copy to JSON",
            data: {
              record_data: data_attributes.to_json,
              table_name: @table_name
            },
            onclick: "copyToJson(this)"
          ) do
            content_tag(:i, "", class: "bi bi-clipboard")
          end

          # Concatenate both buttons
          view_button + copy_factory_button
        end
      end
    end
  end
end
