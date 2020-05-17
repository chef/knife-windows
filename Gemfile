source "https://rubygems.org"

# Specify the gem's dependencies in knife-windows.gemspec
gemspec

group :test do
  gem "rspec", "~> 3.0"
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.6")
    gem "chef-zero", "~> 14"
    gem "chef", "< 16"
  end
  gem "rake"
  gem "chefstyle"
  gem "rb-readline"
end
