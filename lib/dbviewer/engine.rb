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
        Rails.logger.info "DBViewer engine initializing..." if Rails.logger
        Dbviewer.setup
      rescue => e
        puts "Error initializing DBViewer: #{e.message}"
        Rails.logger.error "Error initializing DBViewer: #{e.message}" if Rails.logger
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
