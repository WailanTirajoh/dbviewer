module Dbviewer
  class Engine < ::Rails::Engine
    isolate_namespace Dbviewer

    # Autoload lib directory
    lib_path = File.expand_path("..", __dir__)
    config.autoload_paths << lib_path
    config.eager_load_paths << lib_path

    # Register generators
    config.app_generators do |g|
      g.templates.unshift File.expand_path("../../generators/dbviewer/templates", __dir__)
    end

    # Initialize the engine safely
    initializer "dbviewer.setup", after: :load_config_initializers do |app|
      Dbviewer.setup
    end

    initializer "dbviewer.notifications" do
      Dbviewer::Query::NotificationSubscriber.subscribe
    end
  end
end
