# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "text_attribute/version"

Gem::Specification.new do |s|
  s.name        = "text_attribute"
  s.version     = TextAttribute::VERSION
  s.authors     = ["Andrew Cantino"]
  s.email       = ["andrew@iterationlabs.com"]
  s.homepage    = ""
  s.summary     = %q{Seamlessly store ActiveRecord model attributes in a text file instead of the db. This is good for caching, among other things}
  s.description = %q{}

  s.rubyforge_project = "text_attribute"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", ">= 2.6"
  s.add_development_dependency "rr", ">= 1.0"
end

# Making a new gem with bundler:
# bundle gem lorem
# gem build lorem.gemspec
# gem push lorem-0.0.1.gem
# bundle
# rake -T
# rake build
# rake install
# rake release