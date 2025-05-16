require_relative "lib/dbviewer/version"

Gem::Specification.new do |spec|
  spec.name        = "dbviewer"
  spec.version     = Dbviewer::VERSION
  spec.authors     = [ "Wailan Tirajoh" ]
  spec.email       = [ "wailantirajoh@gmail.com" ]
  spec.homepage    = "https://github.com/wailantirajoh/dbviewer"
  spec.summary     = "A Rails engine for viewing database tables and records."
  spec.description = "DBViewer is a mountable Rails engine that provides a simple interface to view database tables and their records."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wailantirajoh/dbviewer"
  spec.metadata["changelog_uri"] = "https://github.com/wailantirajoh/dbviewer/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "activerecord", ">= 7.0.0"
end
