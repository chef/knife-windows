source "https://rubygems.org"

# Specify your gem's dependencies in knife-windows.gemspec
gemspec

# TODO: Remove this line when a new version of `winrm-s` is released which contains:
#
#   https://github.com/chef/winrm-s/commit/d9a85d7c93ef4c24faaea760cdc58a3532d599e9
#
gem 'winrm-s', github: 'chef/winrm-s'

group :test do
  gem "rspec", '~> 3.0'
  gem "ruby-wmi"
  gem "httpclient"
  gem 'rake'
end
