require "dbviewer/version"
require "dbviewer/engine"
require "dbviewer/initializer"

module Dbviewer
  # Your code goes here...

  # This class method will be called by the engine when it's appropriate
  def self.setup
    Dbviewer::Initializer.setup
  end
end
