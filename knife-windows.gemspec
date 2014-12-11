# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-windows/version"

Gem::Specification.new do |s|
  s.name        = "knife-windows"
  s.version     = Knife::Windows::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seth Chisamore"]
  s.email       = ["schisamo@opscode.com"]
  s.license     = "Apache-2.0"
  s.homepage    = "https://github.com/opscode/knife-windows"
  s.summary     = %q{Plugin that adds functionality to Chef's Knife CLI for configuring/interacting with nodes running Microsoft Windows}
  s.description = s.summary

  s.required_ruby_version	= ">= 1.9.1"
  s.add_dependency "winrm-s", "~> 0.2"

  s.add_development_dependency 'pry'
  s.add_development_dependency 'ohai', '< 8'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
