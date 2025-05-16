module Dbviewer
  class Engine < ::Rails::Engine
    isolate_namespace Dbviewer

    # Ensure lib directory is in the autoload path
    config.autoload_paths << File.expand_path('../../', __FILE__)
    config.eager_load_paths << File.expand_path('../../', __FILE__)

    initializer "dbviewer.assets" do |app|
      # Only configure assets if the assets pipeline is available
      if app.config.respond_to?(:assets)
        app.config.assets.precompile += %w(dbviewer/application.css dbviewer/dbviewer.css)
      end
    end

    # Initialize the engine safely
    initializer "dbviewer.setup", after: :load_config_initializers do |app|
      begin
        Rails.logger.info "[DBViewer] Engine initializing..." if Rails.logger

        # Allow applications to configure DBViewer before setup
        if File.exist?(Rails.root.join("config", "initializers", "dbviewer.rb"))
          Rails.logger.info "[DBViewer] Loading custom configuration from initializer..." if Rails.logger
        end

        # Instead of modifying constants directly, we'll use the class methods
        # defined in the configuration module to provide access to config values

        # Apply configuration and initialize components
        Dbviewer.init

        # Perform additional setup
        Dbviewer.setup
      rescue => e
        puts "Error initializing DBViewer: #{e.message}"
        Rails.logger.error "[DBViewer] Initialization error: #{e.message}" if Rails.logger
        Rails.logger.error e.backtrace.join("\n") if Rails.logger
      end
    end

    # Handle database connections at the appropriate time
    config.to_prepare do
      # Only try to connect when the app is fully initialized
      if Rails.application.initialized? && defined?(ActiveRecord::Base)
        begin
          ActiveRecord::Base.connection
          Rails.logger.info "DBViewer connected to database" if Rails.logger
        rescue => e
          Rails.logger.error "DBViewer database connection error: #{e.message}" if Rails.logger
        end
      end
    end
  end
end
