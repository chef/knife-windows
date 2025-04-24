require "bundler"
Bundler::GemHelper.install_tasks

begin
  require "rspec/core/rake_task"

  task default: %i{spec style}

  desc "Check Linting and code style."
  task :style do
    require "rubocop/rake_task"
    require "cookstyle/chefstyle"

    if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
      # Windows-specific command, rubocop erroneously reports the CRLF in each file which is removed when your PR is uploaeded to GitHub.
      # This is a workaround to ignore the CRLF from the files before running cookstyle.
      sh "cookstyle --chefstyle -c .rubocop.yml --except Layout/EndOfLine"
    else
      sh "cookstyle --chefstyle -c .rubocop.yml"
    end
  rescue LoadError
    puts "Rubocop or Cookstyle gems are not installed. bundle install first to make sure all dependencies are installed."
  end

  desc "Run all unit specs in spec directory"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = "spec/unit/**/*_spec.rb"
  end

rescue LoadError
  STDERR.puts "\n*** RSpec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end
