module Dbviewer
  class Engine < ::Rails::Engine
    isolate_namespace Dbviewer

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
