# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "markdownizer/version"

Gem::Specification.new do |s|
  s.name        = "markdownizer"
  s.version     = Markdownizer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Josep M. Bach", "Josep Jaume Rey", "Oriol Gual"]
  s.email       = ["info@codegram.com"]
  s.homepage    = "http://github.com/codegram/markdownizer"
  s.summary     = %q{Render any text as markdown, with code highlighting and all!}
  s.description = %q{Render any text as markdown, with code highlighting and all!}

  s.rubyforge_project = "markdownizer"

  s.add_runtime_dependency 'activerecord', '>= 3.0.3'
  s.add_runtime_dependency 'rdiscount'
  s.add_runtime_dependency 'coderay'

  s.add_development_dependency 'git'
  s.add_development_dependency 'rspec', '~> 2.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
