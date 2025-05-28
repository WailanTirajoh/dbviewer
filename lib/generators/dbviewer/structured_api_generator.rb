module Dbviewer
  module Generators
    class StructuredApiGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def create_initializer
        template "structured_api_initializer.rb", "config/initializers/dbviewer_structured_api.rb"
      end
    end
  end
end
