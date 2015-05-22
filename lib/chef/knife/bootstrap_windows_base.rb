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
require 'chef/knife/bootstrap'
require 'chef/encrypted_data_bag_item'
require 'chef/knife/core/windows_bootstrap_context'
# Chef 11 PathHelper doesn't have #home
#require 'chef/util/path_helper'

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

          # DEPR: Remove this option in Chef 13
          option :distro,
            :short => "-d DISTRO",
            :long => "--distro DISTRO",
            :description => "Bootstrap a distro using a template. [DEPRECATED] Use --bootstrap-template option instead.",
            :proc        => Proc.new { |v|
              Chef::Log.warn("[DEPRECATED] -d / --distro option is deprecated. Use --bootstrap-template option instead.")
              v
            }

          option :bootstrap_template,
            :long => "--bootstrap-template TEMPLATE",
            :description => "Bootstrap Chef using a built-in or custom template. Set to the full path of an erb template or use one of the built-in templates."

          # DEPR: Remove this option in Chef 13
          option :template_file,
            :long => "--template-file TEMPLATE",
            :description => "Full path to location of template to use. [DEPRECATED] Use --bootstrap-template option instead.",
            :proc        => Proc.new { |v|
              Chef::Log.warn("[DEPRECATED] --template-file option is deprecated. Use --bootstrap-template option instead.")
              v
            }

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

          # Mismatch between option 'encrypted_data_bag_secret' and it's long value '--secret' is by design for compatibility
          option :encrypted_data_bag_secret,
            :short => "-s SECRET",
            :long  => "--secret ",
            :description => "The secret key to use to decrypt data bag item values.  Will be rendered on the node at c:/chef/encrypted_data_bag_secret and set in the rendered client config.",
            :default => false

          # Mismatch between option 'encrypted_data_bag_secret_file' and it's long value '--secret-file' is by design for compatibility
          option :encrypted_data_bag_secret_file,
            :long => "--secret-file SECRET_FILE",
            :description => "A file containing the secret key to use to encrypt data bag item values. Will be rendered on the node at c:/chef/encrypted_data_bag_secret and set in the rendered client config."

          option :auth_timeout,
            :long => "--auth-timeout MINUTES",
            :description => "The maximum time in minutes to wait to for authentication over the transport to the node to succeed. The default value is 2 minutes.",
            :default => 2

          option :node_ssl_verify_mode,
            :long        => "--node-ssl-verify-mode [peer|none]",
            :description => "Whether or not to verify the SSL cert for all HTTPS requests.",
            :proc        => Proc.new { |v|
              valid_values = ["none", "peer"]
              unless valid_values.include?(v)
                raise "Invalid value '#{v}' for --node-ssl-verify-mode. Valid values are: #{valid_values.join(", ")}"
              end
            }

          option :node_verify_api_cert,
            :long        => "--[no-]node-verify-api-cert",
            :description => "Verify the SSL cert for HTTPS requests to the Chef server API.",
            :boolean     => true

          option :msi_url,
            :short => "-u URL",
            :long => "--msi_url URL",
            :description => "Location of the Chef Client MSI. The default templates will prefer to download from this location. The MSI will be downloaded from chef.io if not provided.",
            :default => ''

          option :install_as_service,
            :long => "--install-as-service",
            :description => "Install chef-client as service in windows machine",
            :default => false
        end
      end

      def default_bootstrap_template
        "windows-chef-client-msi"
      end

      def bootstrap_template
        # The order here is important. We want to check if we have the new Chef 12 option is set first.
        # Knife cloud plugins unfortunately all set a default option for the :distro so it should be at
        # the end.
        config[:bootstrap_template] || config[:template_file] || config[:distro] || default_bootstrap_template
      end

       # TODO: This should go away when CHEF-2193 is fixed
      def load_template(template=nil)
        # Are we bootstrapping using an already shipped template?

        template = bootstrap_template

        # Use the template directly if it's a path to an actual file
        if File.exists?(template)
          Chef::Log.debug("Using the specified bootstrap template: #{File.dirname(template)}")
          return IO.read(template).chomp
        end

        # Otherwise search the template directories until we find the right one
        bootstrap_files = []
        bootstrap_files << File.join(File.dirname(__FILE__), 'bootstrap/templates', "#{template}.erb")
        bootstrap_files << File.join(Knife.chef_config_dir, "bootstrap", "#{template}.erb") if Chef::Knife.chef_config_dir
        ::Knife::Windows::PathHelper.all_homes('.chef', 'bootstrap', "#{template}.erb") { |p| bootstrap_files << p }
        bootstrap_files << Gem.find_files(File.join("chef","knife","bootstrap","#{template}.erb"))
        bootstrap_files.flatten!

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

      def bootstrap_context
        @bootstrap_context ||= Knife::Core::WindowsBootstrapContext.new(config, config[:run_list], Chef::Config)
      end

      def render_template(template=nil)
        if config[:secret_file]
          config[:secret] = Chef::EncryptedDataBagItem.load_secret(config[:secret_file])
        end
        Erubis::Eruby.new(template).evaluate(bootstrap_context)
      end

      def bootstrap(proto=nil)
        if Chef::Config[:knife][:encrypted_data_bag_secret_file] || Chef::Config[:knife][:encrypted_data_bag_secret]
          warn_chef_config_secret_key
          config[:secret_file] ||= Chef::Config[:knife][:encrypted_data_bag_secret_file]
          config[:secret] ||= Chef::Config[:knife][:encrypted_data_bag_secret]
        end

        validate_name_args!

        @node_name = Array(@name_args).first
        # back compat--templates may use this setting:
        config[:server_name] = @node_name

        STDOUT.sync = STDERR.sync = true

        if (Chef::Config[:validation_key] && !File.exist?(File.expand_path(Chef::Config[:validation_key])))
          if Chef::VERSION.split('.').first.to_i == 11
            ui.error("Unable to find validation key. Please verify your configuration file for validation_key config value.")
            exit 1
          end

          unless locate_config_value(:chef_node_name)
            ui.error("You must pass a node name with -N when bootstrapping with user credentials")
            exit 1
          end

          client_builder.run
          bootstrap_context.client_pem = client_builder.client_path
        else
          ui.info("Doing old-style registration with the validation key at #{Chef::Config[:validation_key]}...")
          ui.info("Delete your validation key in order to use your user credentials instead")
          ui.info("")
        end

        wait_for_remote_response( config[:auth_timeout].to_i )
        ui.info("Bootstrapping Chef on #{ui.color(@node_name, :bold)}")
        # create a bootstrap.bat file on the node
        # we have to run the remote commands in 2047 char chunks
        create_bootstrap_bat_command do |command_chunk|
          begin
            render_command_result = run_command(command_chunk)
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

      protected

      # Default implementation -- override only if required by the transport
      def wait_for_remote_response(wait_max_minutes)
      end

      def bootstrap_command
        @bootstrap_command ||= "cmd.exe /C #{bootstrap_bat_file}"
      end

      def bootstrap_render_banner_command(chunk_num)
        "cmd.exe /C echo Rendering #{bootstrap_bat_file} chunk #{chunk_num}"
      end

      def escape_windows_batch_characters(line)
        # TODO: The commands are going to get redirected - do we need to escape &?
        line.gsub!(/[(<|>)^]/).each{|m| "^#{m}"}
      end

      def create_bootstrap_bat_command()
        chunk_num = 0
        bootstrap_bat = ""
        banner = bootstrap_render_banner_command(chunk_num += 1)
        render_template(load_template(config[:bootstrap_template])).each_line do |line|
          escape_windows_batch_characters(line)
          # We are guaranteed to have a prefix "banner" command that echo's chunk number.  We can
          # confidently prefix every actual command with &&.
          # TODO: Why does ^\n&& work directly through the commandline but not through SOAP?
          render_line = " && >> #{bootstrap_bat_file} (echo.#{line.chomp.strip})"
          # Windows commands are limited to 8191 characters for machines running XP or higher but
          # this includes the length of environment variables after they have been expanded.
          # Since we don't actually know how long %TEMP% (and it's used twice - once in the banner
          # and once in every command redirection), we simply guess and set the max to 5000.
          # TODO: When a more accurate method is available, fix this.
          if bootstrap_bat.length + render_line.length + banner.length > 5000
            # Can't fit it into this chunk? - flush (if necessary) and then try.
            # Do this first because banner.length might change (e.g. due to an extra digit) and
            # prevent a fit.
            unless bootstrap_bat.empty?
              yield banner + bootstrap_bat
              bootstrap_bat = ""
              banner = bootstrap_render_banner_command(chunk_num += 1)
            end
            # Will this ever fit?
            if render_line.length + banner.length > 5000
              raise "Command in bootstrap template too long by #{render_line.length + banner.length - 5000} characters : #{line}"
            end
          end
          bootstrap_bat << render_line
        end
        raise "Bootstrap template was empty!  Check #{config[:bootstrap_template]}" if bootstrap_bat.empty?
        yield banner + bootstrap_bat
      end

      def bootstrap_bat_file
        @bootstrap_bat_file ||= "\"%TEMP%\\bootstrap-#{Process.pid}-#{Time.now.to_i}.bat\""
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def warn_chef_config_secret_key
        ui.info "* " * 40
        ui.warn(<<-WARNING)
\nSpecifying the encrypted data bag secret key using an 'encrypted_data_bag_secret'
entry in 'knife.rb' is deprecated. Please use the '--secret' or '--secret-file'
options of this command instead.

#{ui.color('IMPORTANT:', :red, :bold)} In a future version of Chef, this
behavior will be removed and any 'encrypted_data_bag_secret' entries in
'knife.rb' will be ignored completely.
        WARNING
        ui.info "* " * 40
      end
    end
  end
end
