source "https://rubygems.org"

# Specify the gem's dependencies in knife-windows.gemspec
gemspec

# Necessary for the external tests in https://github.com/chef/chef
if ENV["GEMFILE_MOD"]
  puts "GEMFILE_MOD: #{ENV["GEMFILE_MOD"]}"
  instance_eval(ENV["GEMFILE_MOD"])
else
  gem "chef", "~> 17"
  gem "ohai", "~> 17"
  gem "knife", "~> 17"
end

group :test do
  gem "rspec", "~> 3.0"
  gem "rake"
  gem "chefstyle"
  gem "rb-readline"
end
