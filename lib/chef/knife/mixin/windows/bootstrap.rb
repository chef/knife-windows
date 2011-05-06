require 'chef/knife'
require 'erubis'

class Chef
  module Mixin
    module Bootstrap

      # TODO: This should go away when CHEF-2193 is fixed
      def load_template(template=nil)
        # Are we bootstrapping using an already shipped template?
        if config[:template_file]
          bootstrap_files = config[:template_file]
        else
          bootstrap_files = []
          bootstrap_files << File.join(File.dirname(__FILE__), 'bootstrap', "#{config[:distro]}.erb")
          bootstrap_files << File.join(Dir.pwd, ".chef", "bootstrap", "#{config[:distro]}.erb")
          bootstrap_files << File.join(ENV['HOME'], '.chef', 'bootstrap', "#{config[:distro]}.erb")
          bootstrap_files << Gem.find_files(File.join("chef","knife","bootstrap","#{config[:distro]}.erb"))
          bootstrap_files.flatten!
        end

        template = Array(bootstrap_files).find do |bootstrap_template|
          Chef::Log.debug("Looking for bootstrap template in #{File.dirname(bootstrap_template)}")
          ::File.exists?(bootstrap_template)
        end

        unless template
          ui.info("Can not find bootstrap definition for #{config[:distro]}")
          raise Errno::ENOENT
        end

        Chef::Log.debug("Found bootstrap template in #{File.dirname(template)}")

        IO.read(template).chomp
      end

      def render_template(template=nil)
        context = Knife::Core::WindowsBootstrapContext.new(config, config[:run_list], Chef::Config)
        Erubis::Eruby.new(template).evaluate(context)
      end

      def bootstrap(proto=nil)

        validate_name_args!

        @node_name = Array(@name_args).first
        # back compat--templates may use this setting:
        config[:server_name] = @node_name

        $stdout.sync = true

        ui.info("Bootstrapping Chef on #{ui.color(@node_name, :bold)}")
        # create a bootstrap.bat file on the node
        # we have to run the remote commands in 2047 char chunks
        create_bootstrap_bat_command do |command_chunk, chunk_num|
          run_command("cmd.exe /C echo \"Rendering bootstrap.bat chunk #{chunk_num}\" && #{command_chunk}").run
        end

        # execute the bootstrap.bat file
        run_command(bootstrap_command).run
      end

      def bootstrap_command
        @bootstrap_command ||= "cmd.exe /C #{bootstrap_bat_file}"
      end

      def create_bootstrap_bat_command(&block)
        bootstrap_bat = []
        chunk_num = 0
        render_template(load_template(config[:bootstrap_template])).each_line do |line|
          # escape WIN BATCH special chars
          line.gsub!(/[(<|>)^]/).each{|m| "^#{m}"}
          # windows commands are limited to 2047 characters
          if((bootstrap_bat + [line]).join(" && ").size > 2047 )
            yield bootstrap_bat.join(" && "), chunk_num += 1
            bootstrap_bat = []
          end
          bootstrap_bat << ">> #{bootstrap_bat_file} (echo.#{line.chomp.strip})"
        end
        yield bootstrap_bat.join(" && "), chunk_num += 1
      end

      def bootstrap_bat_file
        "%TEMP%\\bootstrap.bat"
      end

      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end

    end
  end
end