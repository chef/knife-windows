#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife'
require 'chef/encrypted_data_bag_item'
require 'chef/knife/core/windows_bootstrap_context'

class Chef
  class Knife
    module BootstrapWindowsBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'readline'
            require 'chef/json_compat'
          end

          option :chef_node_name,
            :short => "-N NAME",
            :long => "--node-name NAME",
            :description => "The Chef node name for your new node"

          option :prerelease,
            :long => "--prerelease",
            :description => "Install the pre-release chef gems"

          option :bootstrap_version,
            :long => "--bootstrap-version VERSION",
            :description => "The version of Chef to install",
            :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

          option :bootstrap_proxy,
            :long => "--bootstrap-proxy PROXY_URL",
            :description => "The proxy server for the node being bootstrapped",
            :proc => Proc.new { |p| Chef::Config[:knife][:bootstrap_proxy] = p }

          option :bootstrap_no_proxy,
            :long => "--bootstrap-no-proxy ",
            :description => "Avoid a proxy server for the given addresses",
            :proc => Proc.new { |np| Chef::Config[:knife][:bootstrap_no_proxy] = np }

          option :distro,
            :short => "-d DISTRO",
            :long => "--distro DISTRO",
            :description => "Bootstrap a distro using a template",
            :default => "windows-chef-client-msi"

          option :template_file,
            :long => "--template-file TEMPLATE",
            :description => "Full path to location of template to use",
            :default => false

          option :run_list,
            :short => "-r RUN_LIST",
            :long => "--run-list RUN_LIST",
            :description => "Comma separated list of roles/recipes to apply",
            :proc => lambda { |o| o.split(",") },
            :default => []

          option :first_boot_attributes,
            :short => "-j JSON_ATTRIBS",
            :long => "--json-attributes",
            :description => "A JSON string to be added to the first run of chef-client",
            :proc => lambda { |o| JSON.parse(o) },
            :default => {}

          option :encrypted_data_bag_secret,
            :short => "-s SECRET",
            :long  => "--secret ",
            :description => "The secret key to use to decrypt data bag item values.  Will be rendered on the node at c:/chef/encrypted_data_bag_secret and set in the rendered client config.",
            :default => false

          option :encrypted_data_bag_secret_file,
            :long => "--secret-file SECRET_FILE",
            :description => "A file containing the secret key to use to encrypt data bag item values. Will be rendered on the node at c:/chef/encrypted_data_bag_secret and set in the rendered client config."

        end
      end

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
        if config[:encrypted_data_bag_secret_file]
          config[:encrypted_data_bag_secret] = Chef::EncryptedDataBagItem.load_secret(config[:encrypted_data_bag_secret_file])
        end
        context = Knife::Core::WindowsBootstrapContext.new(config, config[:run_list], Chef::Config)
        Erubis::Eruby.new(template).evaluate(context)
      end

      def bootstrap(proto=nil)

        validate_name_args!

        @node_name = Array(@name_args).first
        # back compat--templates may use this setting:
        config[:server_name] = @node_name

        STDOUT.sync = STDERR.sync = true

        wait_for_winrm_response
        ui.info("Bootstrapping Chef on #{ui.color(@node_name, :bold)}")
        # create a bootstrap.bat file on the node
        # we have to run the remote commands in 2047 char chunks
        create_bootstrap_bat_command do |command_chunk, chunk_num|
          begin
            render_command_result = run_command(%Q!cmd.exe /C echo "Rendering #{bootstrap_bat_file} chunk #{chunk_num}" && #{command_chunk}!)
            ui.error("Batch render command returned #{render_command_result}") if render_command_result != 0
            render_command_result
          rescue SystemExit => e
            raise unless e.success?
          end
        end

        # execute the bootstrap.bat file
        bootstrap_command_result = run_command(bootstrap_command)
        ui.error("Bootstrap command returned #{bootstrap_command_result}") if bootstrap_command_result != 0
        bootstrap_command_result
      end

      def wait_for_winrm_response(wait_max_minutes = 25)
        wait_max_seconds = wait_max_minutes * 60
        retry_interval_seconds = 10
        retries_left = wait_max_seconds / retry_interval_seconds

        print(ui.color("\nWaiting for WinRM response before bootstrap", :magenta))

        wait_start_time = Time.now

        begin
          print(".")
          # Return status of the command is non-zero, typically nil,
          # for our simple echo command in cases where run_command
          # swallows the exception, such as 401's. Treat such cases
          # the same as the case where we encounter an exception.
          status = run_command("echo . & echo Response received.")
          raise RunTimeError, 'Command execution failed.' if status != 0
          ui.info(ui.color("WinRM responded after #{elapsed_time_in_minutes(wait_start_time)} minutes.", :magenta))
          return
        rescue
          retries_left -= 1
          if retries_left <= 0 || (elapsed_time_in_minutes(wait_start_time) > wait_max_minutes)
            ui.error("No response received from WinRM after #{elapsed_time_in_minutes(wait_start_time)} minutes, giving up.")
            raise
          end
          sleep retry_interval_seconds
          retry
        end
      end

      def elapsed_time_in_minutes(start_time)
        ((Time.now - start_time) / 60).round(2)        
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
        @bootstrap_bat_file ||= "\"%TEMP%\\bootstrap-#{Process.pid}-#{Time.now.to_i}.bat\""
      end

      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end
    end
  end
end
