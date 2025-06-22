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

    # Configure assets for the engine
    initializer "dbviewer.assets" do |app|
      # Add engine assets path to asset load paths
      app.config.assets.paths << root.join("app", "assets", "javascripts").to_s
      app.config.assets.paths << root.join("app", "assets", "stylesheets").to_s
      app.config.assets.paths << root.join("app", "assets", "images").to_s

      # Make sure we precompile individual JavaScript files
      app.config.assets.precompile += %w[
        dbviewer/utility.js
        dbviewer/error_handler.js
        dbviewer/home.js
        dbviewer/layout.js
        dbviewer/sidebar.js
        dbviewer/query.js
        dbviewer/entity_relationship_diagram.js
        dbviewer/table.js
      ]

      # Make sure stylesheets are precompiled too
      app.config.assets.precompile += %w[
        dbviewer/application.css
        dbviewer/home.css
        dbviewer/query.css
        dbviewer/table.css
        dbviewer/entity_relationship_diagram.css
      ]
    end
  end
end
