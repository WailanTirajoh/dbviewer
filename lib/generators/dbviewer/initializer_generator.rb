module Dbviewer
  module Generators
    class InitializerGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)
      desc "Creates a DBViewer initializer file at config/initializers/dbviewer.rb"

      def copy_initializer_file
        copy_file "initializer.rb", "config/initializers/dbviewer.rb"
      end
    end
  end
end
