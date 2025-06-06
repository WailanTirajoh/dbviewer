module Dbviewer
  module SortingHelper
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
  end
end
