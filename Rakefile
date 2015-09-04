require 'bundler'
Bundler::GemHelper.install_tasks

begin
  require 'rspec/core/rake_task'

  task :default => [:unit_spec, :functional_spec]

  desc "Run all functional specs in spec directory"
  RSpec::Core::RakeTask.new(:functional_spec) do |t|
    t.pattern = 'spec/functional/**/*_spec.rb'
  end

  desc "Run all unit specs in spec directory"
  RSpec::Core::RakeTask.new(:unit_spec) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

rescue LoadError
  STDERR.puts "\n*** RSpec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end
