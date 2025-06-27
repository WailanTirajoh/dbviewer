module Dbviewer
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)
      desc "Creates a DBViewer initializer file at config/initializers/dbviewer.rb"

      def copy_initializer_file
        copy_file "initializer.rb", "config/initializers/dbviewer.rb"
      end

      def copy_pii_example
        copy_file "pii_configuration_example.rb", "config/initializers/dbviewer_pii_example.rb"
        say "Created example PII configuration at config/initializers/dbviewer_pii_example.rb", :green
        say "Review and customize the PII masking rules, then rename to dbviewer_pii.rb to activate.", :yellow
      end
    end
  end
end
