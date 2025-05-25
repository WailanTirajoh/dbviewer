module Dbviewer
  class Engine < ::Rails::Engine
    isolate_namespace Dbviewer

    # Ensure lib directory is in the autoload path
    config.autoload_paths << File.expand_path("../../", __FILE__)
    config.eager_load_paths << File.expand_path("../../", __FILE__)

    # Register generators
    config.app_generators do |g|
      g.templates.unshift File.expand_path("../../generators/dbviewer/templates", __dir__)
    end

    # Initialize the engine safely
    initializer "dbviewer.setup", after: :load_config_initializers do |app|
      Dbviewer.init
      Dbviewer.setup
    end

    initializer "dbviewer.notifications" do
      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        Logger.instance.add(event)
      end
    end
  end
end
