$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "activity/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "activity"
  s.version     = Activity::VERSION
  s.authors     = ["Julien Guimont"]
  s.email       = ["julien.guimont@gmail.com  "]
  s.homepage    = "http://jguimont.com"
  s.summary     = "User activity feed"
  s.description = "User activity feed"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.1"

end
