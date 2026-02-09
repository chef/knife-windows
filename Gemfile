source "https://rubygems.org"

# Specify the gem's dependencies in knife-windows.gemspec
gemspec

# Necessary for the external tests in https://github.com/chef/chef
if ENV["GEMFILE_MOD"]
  puts "GEMFILE_MOD: #{ENV["GEMFILE_MOD"]}"
  instance_eval(ENV["GEMFILE_MOD"])
else
  # changed to 18-stable given that it's the newest compatible with
  # the latest knife (and knife is embedded in chef so can't just point at
  # GitHub)
  gem "ohai", git: "https://github.com/chef/ohai", branch: "18-stable"
  gem "knife"
end

group :test do
  gem "rspec", "~> 3.0"
  gem "rake"
  gem "rb-readline"
end
