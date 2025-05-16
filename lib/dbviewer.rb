require "dbviewer/version"
require "dbviewer/engine"
require "dbviewer/initializer"
require "dbviewer/database_manager"
require "dbviewer/sql_validator"

module Dbviewer
  # Main module for the database viewer

  # This class method will be called by the engine when it's appropriate
  def self.setup
    Dbviewer::Initializer.setup
  end
end
