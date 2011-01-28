# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "nagios_analyzer/version"

Gem::Specification.new do |s|
  s.name        = "nagios_analyzer"
  s.version     = NagiosAnalyzer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jean-Baptiste Barth"]
  s.email       = ["jeanbaptiste.barth@gmail.com"]
  s.homepage    = "http://github.com/jbbarth/nagios_analyzer"
  s.summary     = %q{Parses a nagios/shinken status.dat file}
  s.description = %q{Helps you parse a status.dat file produced by nagios or shinken. It aims at being performant for big status.dat files. Take a look at nagios_parser too if you want, looks very cool too !}

  s.rubyforge_project = "nagios_analyzer"

  s.add_development_dependency "rspec"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
