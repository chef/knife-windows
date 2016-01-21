source "https://rubygems.org"

# Specify your gem's dependencies in knife-windows.gemspec
gemspec

gem 'winrm', git: 'https://github.com/WinRb/WinRM', branch: 'dan/ntlm-encryption-squashed'
gem 'rubyntlm', git: 'https://github.com/mwrock/rubyntlm.git', branch: 'domain'

group :test do
  gem "chef"
  gem "rspec", '~> 3.0'
  gem "ruby-wmi"
  gem "httpclient"
  gem 'rake'
end
