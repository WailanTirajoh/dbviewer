module Dbviewer
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)
      desc "Creates a DBViewer initializer file at config/initializers/dbviewer.rb"

      def copy_initializer_file
        copy_file "initializer.rb", "config/initializers/dbviewer.rb"
      end

      def copy_pii
        copy_file "dbviewer_pii.rb", "config/initializers/dbviewer_pii.rb"
      end
    end
  end
end
