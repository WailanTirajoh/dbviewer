module Dbviewer
  module ApplicationHelper
    # Check if a table has a created_at column
    def has_timestamp_column?(table_name)
      return false unless table_name.present?

      # Get the columns for the table directly using DatabaseManager
      columns = get_database_manager.table_columns(table_name)
      columns.any? { |col| col[:name] == "created_at" && [ :datetime, :timestamp ].include?(col[:type]) }
    end

    # Helper to access the database manager
    def get_database_manager
      @database_manager ||= ::Dbviewer::DatabaseManager.new
    end

    # Extract column type from columns info
    def column_type_from_info(column_name, columns)
      return nil unless columns.present?

      column_info = columns.find { |c| c[:name].to_s == column_name.to_s }
      column_info ? column_info[:type].to_s.downcase : nil
    end

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
      if column_type && (column_type =~ /datetime/ || column_type =~ /^date$/ || column_type =~ /^time$/)
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
    end

    # Render column filter input based on column type
    def render_column_filter_input(form, column_name, column_type, column_filters)
      if column_type && column_type =~ /datetime/
        form.datetime_local_field("column_filters[#{column_name}]",
          value: column_filters[column_name],
          class: "form-control form-control-sm column-filter rounded-0",
          data: { column: column_name })
      elsif column_type && column_type =~ /^date$/
        form.date_field("column_filters[#{column_name}]",
          value: column_filters[column_name],
          class: "form-control form-control-sm column-filter rounded-0",
          data: { column: column_name })
      elsif column_type && column_type =~ /^time$/
        form.time_field("column_filters[#{column_name}]",
          value: column_filters[column_name],
          class: "form-control form-control-sm column-filter rounded-0",
          data: { column: column_name })
      else
        form.text_field("column_filters[#{column_name}]",
          value: column_filters[column_name],
          placeholder: "",
          class: "form-control form-control-sm column-filter rounded-0",
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
        { class: "form-select form-select-sm operator-select" })
    end

    # Render complete filter input group for a column
    def render_column_filter(form, column_name, columns, column_filters)
      column_type = column_type_from_info(column_name, columns)

      content_tag(:div, class: "filter-input-group") do
        render_operator_select(form, column_name, column_type, column_filters) +
        render_column_filter_input(form, column_name, column_type, column_filters)
      end
    end

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

    # Common parameters for pagination and filtering
    def common_params(options = {})
      params = {
        order_by: @order_by,
        order_direction: @order_direction,
        per_page: @per_page,
        column_filters: @column_filters
      }.merge(options)

      # Add creation filters if they exist
      params[:creation_filter_start] = @creation_filter_start if @creation_filter_start.present?
      params[:creation_filter_end] = @creation_filter_end if @creation_filter_end.present?

      params
    end

    # Render pagination UI
    def render_pagination(table_name, current_page, total_pages, params = {})
      return unless total_pages && total_pages > 1

      content_tag(:nav, 'aria-label': "Page navigation") do
        content_tag(:ul, class: "pagination justify-content-center") do
          prev_link = content_tag(:li, class: "page-item #{current_page == 1 ? 'disabled' : ''}") do
            link_to "«", table_path(table_name, params.merge(page: [ current_page - 1, 1 ].max)), class: "page-link"
          end

          # Calculate page range to display
          start_page = [ 1, current_page - 2 ].max
          end_page = [ start_page + 4, total_pages ].min
          start_page = [ 1, end_page - 4 ].max

          # Generate page links
          page_links = (start_page..end_page).map do |page_num|
            content_tag(:li, class: "page-item #{page_num == current_page ? 'active' : ''}") do
              link_to page_num, table_path(table_name, params.merge(page: page_num)), class: "page-link"
            end
          end.join.html_safe

          next_link = content_tag(:li, class: "page-item #{current_page == total_pages ? 'disabled' : ''}") do
            link_to "»", table_path(table_name, params.merge(page: [ current_page + 1, total_pages ].min)), class: "page-link"
          end

          prev_link + page_links + next_link
        end
      end
    end

    # Generate URL parameters for per-page dropdown
    def per_page_url_params(table_name)
      # Start with the dynamic part for the select element
      url_params = "per_page=' + this.value + '&page=1"

      # Add all other common parameters except per_page and page which we already set
      params = common_params.except(:per_page, :page)

      # Convert the params hash to URL parameters
      params.each do |key, value|
        if key == :column_filters && value.is_a?(Hash) && value.reject { |_, v| v.blank? }.any?
          value.reject { |_, v| v.blank? }.each do |filter_key, filter_value|
            url_params += "&column_filters[#{filter_key}]=#{CGI.escape(filter_value.to_s)}"
          end
        elsif value.present?
          url_params += "&#{key}=#{CGI.escape(value.to_s)}"
        end
      end

      url_params
    end

    # Render time grouping links
    def time_grouping_links(table_name, current_grouping)
      params = common_params

      content_tag(:div, class: "btn-group btn-group-sm", role: "group", 'aria-label': "Time grouping") do
        [
          link_to("Hourly", table_path(table_name, params.merge(time_group: "hourly")),
                 class: "btn btn-outline-primary #{current_grouping == 'hourly' ? 'active' : ''}"),
          link_to("Daily", table_path(table_name, params.merge(time_group: "daily")),
                 class: "btn btn-outline-primary #{current_grouping == 'daily' ? 'active' : ''}"),
          link_to("Weekly", table_path(table_name, params.merge(time_group: "weekly")),
                 class: "btn btn-outline-primary #{current_grouping == 'weekly' ? 'active' : ''}")
        ].join.html_safe
      end
    end

    # Dark mode helper methods

    # Returns the theme toggle icon based on the current theme
    def theme_toggle_icon
      '<i class="bi bi-moon"></i><i class="bi bi-sun"></i>'.html_safe
    end

    # Returns the aria label for the theme toggle button
    def theme_toggle_label
      "Toggle dark mode"
    end

    # Returns the appropriate background class for stat cards that adapts to dark mode
    def stat_card_bg_class
      "stat-card-bg"
    end

    # Helper method for code blocks background that adapts to dark mode
    def code_block_bg_class
      "sql-code-block"
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

    # Helper method to determine if current controller and action match
    def active_nav_class(controller_name, action_name = nil)
      current_controller = params[:controller].split("/").last
      active = current_controller == controller_name

      if action_name.present?
        active = active && params[:action] == action_name
      end

      active ? "active" : ""
    end

    # Helper for highlighting dashboard link
    def dashboard_nav_class
      active_nav_class("home")
    end

    # Helper for highlighting tables link
    def tables_nav_class
      active_nav_class("tables")
    end

    # Helper for highlighting ERD link
    def erd_nav_class
      active_nav_class("entity_relationship_diagrams")
    end

    # Helper for highlighting SQL Logs link
    def logs_nav_class
      active_nav_class("logs")
    end

    # Returns a sort icon based on the current sort direction
    def sort_icon(column_name, current_order_by, current_direction)
      if column_name == current_order_by
        direction = current_direction == "ASC" ? "up" : "down"
        "<i class='bi bi-sort-#{direction}'></i>".html_safe
      else
        "<i class='bi bi-filter invisible sort-icon'></i>".html_safe
      end
    end

    # Determine the next sort direction based on the current one
    def next_sort_direction(column_name, current_order_by, current_direction)
      if column_name == current_order_by && current_direction == "ASC"
        "DESC"
      else
        "ASC"
      end
    end

    # Generate a sortable column header link
    def sortable_column_header(column_name, current_order_by, current_direction, table_name, current_page, per_page, column_filters)
      is_sorted = column_name == current_order_by
      sort_direction = next_sort_direction(column_name, current_order_by, current_direction)

      aria_sort = if is_sorted
        current_direction.downcase == "asc" ? "ascending" : "descending"
      else
        "none"
      end

      # Use common_params helper to build parameters
      sort_params = common_params(order_by: column_name, order_direction: sort_direction)

      link_to table_path(table_name, sort_params),
        class: "d-flex align-items-center text-decoration-none text-reset column-sort-link",
        title: "Sort by #{column_name} (#{sort_direction.downcase})",
        "aria-sort": aria_sort,
        role: "button",
        tabindex: "0" do
          content_tag(:span, column_name, class: "column-name") +
          content_tag(:span, sort_icon(column_name, current_order_by, current_direction), class: "sort-icon-container")
      end
    end

    # Render a complete table header row with sortable columns
    def render_sortable_header_row(records, order_by, order_direction, table_name, current_page, per_page, column_filters)
      return content_tag(:tr) { content_tag(:th, "No columns available") } unless records&.columns

      content_tag(:tr) do
        # Start with action column header (sticky first column)
        headers = [
          content_tag(:th, class: "px-3 py-2 text-center action-column action-column-header", width: "60px", rowspan: 2) do
            content_tag(:span, "Actions")
          end
        ]

        # Add all data columns
        headers += records.columns.map do |column_name|
          is_sorted = order_by == column_name
          content_tag(:th, class: "px-3 py-2 sortable-column #{is_sorted ? 'sorted' : ''}") do
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
          content_tag(:th, class: "p-0") do
            render_column_filter(form, column_name, columns, column_filters)
          end
        end

        filters.join.html_safe
      end
    end

    # Render a cell that may include a foreign key link
    def render_table_cell(cell, column_name, metadata)
      cell_value = format_cell_value(cell)
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
    def render_table_row(row, records, metadata)
      content_tag(:tr) do
        # Start with action column (sticky first column)
        cells = [ render_action_cell(row, records.columns, metadata) ]

        # Add all data cells
        cells += row.each_with_index.map do |cell, cell_index|
          column_name = records.columns[cell_index]
          render_table_cell(cell, column_name, metadata)
        end

        cells.join.html_safe
      end
    end

    # Render the entire table body with rows
    def render_table_body(records, metadata)
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
            render_table_row(row, records, metadata)
          end.join.html_safe
        end
      end
    end

    # Render action buttons for a record
    def render_action_cell(row_data, columns, metadata = nil)
      data_attributes = {}

      # Create a hash of column_name: value pairs for data attributes
      columns.each_with_index do |column_name, index|
        data_attributes[column_name] = row_data[index].to_s
      end

      content_tag(:td, class: "text-center action-column") do
        button_tag(
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
      end
    end
  end
end
