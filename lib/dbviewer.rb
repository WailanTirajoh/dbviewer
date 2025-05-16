require "dbviewer/version"
require "dbviewer/engine"
require "dbviewer/initializer"

module Dbviewer
  # Main module for the database viewer

  # Auto-load the database manager model
  autoload :DatabaseManager, 'dbviewer/database_manager'

  # This class method will be called by the engine when it's appropriate
  def self.setup
    Dbviewer::Initializer.setup
  end
end

# Require core files
require "dbviewer/database_manager"
