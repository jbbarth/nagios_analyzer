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
  s.description = <<-EOH
  nagios_analyzer gem allows you to parse a status.dat file produced by nagios or shinken.
  
  It's similar to nagios_parser in some way, but has different goals:
  * the parser doesn't rely on 3rd party library nor standard parser like 'racc', I want to keep the code very simple to read and maintain ;
  * the parser supports defining scopes, which are processed on the raw file for performance concern, ruby objects being instanciated lately when necessary : on my conf (85hosts/700services), spawning a ruby object for each section makes the script at least 10 times slower (0.25s => >3s). Most of the time, you'll only want to access a subset of your services or hosts, so it's ok.
  
  Since nagios_parser looks very cool too, you should try both and keep the best one for you.
  EOH

  s.rubyforge_project = "nagios_analyzer"

  s.add_development_dependency "rspec"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
