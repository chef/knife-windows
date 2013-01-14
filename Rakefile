require 'bundler'
Bundler::GemHelper.install_tasks

begin
  require 'rspec/core/rake_task'

  task :default => :spec

  desc "Run all specs in spec directory"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/functional/**/*_spec.rb'
  end

rescue LoadError
  STDERR.puts "\n*** RSpec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end
