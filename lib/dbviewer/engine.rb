module Dbviewer
  class Engine < ::Rails::Engine
    isolate_namespace Dbviewer

    # Ensure lib directory is in the autoload path
    config.autoload_paths << File.expand_path("../../", __FILE__)
    config.eager_load_paths << File.expand_path("../../", __FILE__)

    # Initialize the engine safely
    initializer "dbviewer.setup", after: :load_config_initializers do |app|
      Dbviewer.init
      Dbviewer.setup
    end

    # Handle database connections at the appropriate time
    config.to_prepare do
      ActiveRecord::Base.connection if Rails.application.initialized?
    end
  end
end
