module Dbviewer
  module Api
    class DatabaseController < BaseController
      def size
        begin
          size = calculate_schema_size
          render_success(schema_size: size)
        rescue => e
          render_error("Error calculating schema size: #{e.message}")
        end
      end
    end
  end
end
