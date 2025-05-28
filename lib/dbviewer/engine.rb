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
      Dbviewer.init
      Dbviewer.setup
    end

    initializer "dbviewer.notifications" do
      return unless Rails.env.development?

      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)

        next if skip_internal_query?(event)

        Dbviewer::Logger.instance.add(event)
      end
    end

    private

    def skip_internal_query?(event)
      caller_locations = caller_locations(1)
      return false unless caller_locations

      excluded_caller_locations = caller_locations.filter do |caller_location|
        !caller_location.path.include?("lib/dbviewer/engine.rb")
      end
      excluded_caller_locations.any? { |l| l.path.include?("dbviewer") }
    end
  end
end
