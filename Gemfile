source "https://rubygems.org"

# Specify the gem's dependencies in knife-windows.gemspec
gemspec

# Necessary for the external tests in https://github.com/chef/chef
if ENV["GEMFILE_MOD"]
  puts "GEMFILE_MOD: #{ENV["GEMFILE_MOD"]}"
  instance_eval(ENV["GEMFILE_MOD"])
else
  gem "chef-utils", "17.4.38"
  gem "chef", git: "https://github.com/chef/chef", branch: "main"
  gem "ohai", git: "https://github.com/chef/ohai", branch: "main"
  gem "knife"
end

group :test do
  gem "rspec", "~> 3.0"
  gem "rake"
  gem "chefstyle"
  gem "rb-readline"
end
