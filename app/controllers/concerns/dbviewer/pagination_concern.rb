module Dbviewer
  module PaginationConcern
    extend ActiveSupport::Concern

    included do
      # Sort direction validation
      const_set(:VALID_SORT_DIRECTIONS, %w[ASC DESC].freeze) unless const_defined?(:VALID_SORT_DIRECTIONS)
    end

    module ClassMethods
      # Use configuration values from Dbviewer module
      def per_page_options
        Dbviewer.configuration.per_page_options
      end

      def default_per_page
        Dbviewer.configuration.default_per_page
      end
    end

    # Set pagination parameters from request or defaults
    def set_pagination_params
      @current_page = [ 1, params[:page].to_i ].max
      @per_page = params[:per_page] ? params[:per_page].to_i : self.class.default_per_page
      @per_page = self.class.default_per_page unless self.class.per_page_options.include?(@per_page)
    end

    # Set sorting parameters from request or defaults
    def set_sorting_params
      @order_by = params[:order_by].presence ||
                  database_manager.primary_key(@table_name).presence ||
                  (@columns.first ? @columns.first[:name] : nil)

      @order_direction = params[:order_direction].upcase if params[:order_direction].present?
      @order_direction = "ASC" unless self.class::VALID_SORT_DIRECTIONS.include?(@order_direction)
    end

    def fetch_total_count(table_name, query_params)
      if query_params.column_filters.present? && query_params.column_filters.values.any?(&:present?)
        fetch_filtered_record_count(table_name, query_params.column_filters)
      else
        fetch_table_record_count(table_name)
      end
    end

    # Calculate the total number of pages
    def calculate_total_pages(total_count, per_page)
      (total_count.to_f / per_page).ceil
    end
  end
end
