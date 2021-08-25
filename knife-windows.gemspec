$:.push File.expand_path("lib", __dir__)
require "knife-windows/version"

Gem::Specification.new do |s|
  s.name        = "knife-windows"
  s.version     = Knife::Windows::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seth Chisamore"]
  s.email       = ["schisamo@chef.io"]
  s.license     = "Apache-2.0"
  s.homepage    = "https://github.com/chef/knife-windows"
  s.summary     = %q{Plugin that adds functionality to Chef Infra's Knife CLI for configuring/interacting with nodes running Microsoft Windows}
  s.description = s.summary

  s.required_ruby_version = ">= 3.0.2"
  s.add_dependency "chef", ">= 15.11"
  s.add_dependency "winrm", "~> 2.1"
  s.add_dependency "winrm-elevated", "~> 1.0"

  s.add_development_dependency "pry"

  s.files = %w{LICENSE} + Dir.glob("{spec,lib}/**/*")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]
end
