source "https://rubygems.org"

# Specify your gem's dependencies in knife-windows.gemspec
gemspec

# TODO - remove branch on winrm-s merge.
gem 'winrm-s', :github => 'opscode/winrm-s',
  :branch => 'winrm-sspi-nego'

group :test do
  gem "rspec"
  gem "ruby-wmi"
  gem "chef"
  gem 'rake'
end
