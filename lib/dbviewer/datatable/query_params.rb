module Dbviewer
  module Datatable
    # QueryParams encapsulates parameters for table querying operations
    class QueryParams
      attr_reader :page, :order_by, :direction, :per_page, :column_filters, :max_records

      # Initialize query parameters with defaults
      # @param page [Integer] Page number (1-based)
      # @param order_by [String, nil] Column to sort by
      # @param direction [String] Sort direction ('ASC' or 'DESC')
      # @param per_page [Integer, nil] Number of records per page
      # @param column_filters [Hash, nil] Hash of column filters
      # @param max_records [Integer] Maximum number of records to fetch
      def initialize(
        page: 1,
        order_by: nil,
        direction: "ASC",
        per_page: nil,
        column_filters: nil,
        max_records: 1000
      )
        @page = [ 1, page.to_i ].max
        @order_by = order_by
        @direction = normalize_direction(direction)
        @per_page = normalize_per_page(per_page || 25, max_records)
        @column_filters = column_filters || {}
        @max_records = max_records
      end

      private

      def normalize_direction(dir)
        %w[ASC DESC].include?(dir.to_s.upcase) ? dir.to_s.upcase : "ASC"
      end

      def normalize_per_page(per_page_value, max)
        [ per_page_value.to_i, max ].min
      end
    end
  end
end
