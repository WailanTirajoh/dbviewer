module Dbviewer
  module PaginationHelper
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
  end
end
