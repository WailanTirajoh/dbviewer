module Dbviewer
  module Api
    class DatabaseController < BaseController
      def size
        size = database_manager.fetch_schema_size
        render_success(schema_size: size)
      end
    end
  end
end
