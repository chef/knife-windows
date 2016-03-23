#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2011-2016 Chef Software, Inc.
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
require 'chef/knife/knife_windows_base'
# Chef 11 PathHelper doesn't have #home
#require 'chef/util/path_helper'

class Chef
  class Knife
    module BootstrapWindowsBase

      include Chef::Knife::KnifeWindowsBase

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
            :long => "--bootstrap-no-proxy [NO_PROXY_URL|NO_PROXY_IP]",
            :description => "Do not proxy locations for the node being bootstrapped; this option is used internally by Opscode",
            :proc => Proc.new { |np| Chef::Config[:knife][:bootstrap_no_proxy] = np }

          option :bootstrap_install_command,
            :long        => "--bootstrap-install-command COMMANDS",
            :description => "Custom command to install chef-client",
            :proc        => Proc.new { |ic| Chef::Config[:knife][:bootstrap_install_command] = ic }

          # DEPR: Remove this option in Chef 13
          option :distro,
            :short => "-d DISTRO",
            :long => "--distro DISTRO",
            :description => "Bootstrap a distro using a template. [DEPRECATED] Use -t / --bootstrap-template option instead.",
            :proc        => Proc.new { |v|
              Chef::Log.warn("[DEPRECATED] -d / --distro option is deprecated. Use --bootstrap-template option instead.")
              v
            }

          option :bootstrap_template,
            :short => "-t TEMPLATE",
            :long => "--bootstrap-template TEMPLATE",
            :description => "Bootstrap Chef using a built-in or custom template. Set to the full path of an erb template or use one of the built-in templates."

          # DEPR: Remove this option in Chef 13
          option :template_file,
            :long => "--template-file TEMPLATE",
            :description => "Full path to location of template to use. [DEPRECATED] Use -t / --bootstrap-template option instead.",
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

          option :hint,
            :long => "--hint HINT_NAME[=HINT_FILE]",
            :description => "Specify Ohai Hint to be set on the bootstrap target. Use multiple --hint options to specify multiple hints.",
            :proc => Proc.new { |h|
              Chef::Config[:knife][:hints] ||= Hash.new
              name, path = h.split("=")
              Chef::Config[:knife][:hints][name] = path ? Chef::JSONCompat.parse(::File.read(path)) : Hash.new
            }

          option :first_boot_attributes,
            :short => "-j JSON_ATTRIBS",
            :long => "--json-attributes",
            :description => "A JSON string to be added to the first run of chef-client",
            :proc => lambda { |o| JSON.parse(o) },
            :default => nil

          option :first_boot_attributes_from_file,
            :long => "--json-attribute-file FILE",
            :description => "A JSON file to be used to the first run of chef-client",
            :proc => lambda { |o| Chef::JSONCompat.parse(File.read(o)) },
            :default => nil

          # Mismatch between option 'encrypted_data_bag_secret' and it's long value '--secret' is by design for compatibility
          option :encrypted_data_bag_secret,
            :short => "-s SECRET",
            :long  => "--secret ",
            :description => "The secret key to use to decrypt data bag item values. Will be rendered on the node at c:/chef/encrypted_data_bag_secret and set in the rendered client config.",
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
            :long => "--msi-url URL",
            :description => "Location of the Chef Client MSI. The default templates will prefer to download from this location. The MSI will be downloaded from chef.io if not provided.",
            :default => ''

          option :install_as_service,
            :long => "--install-as-service",
            :description => "Install chef-client as a Windows service",
            :default => false

          option :bootstrap_vault_file,
          :long        => '--bootstrap-vault-file VAULT_FILE',
          :description => 'A JSON file with a list of vault(s) and item(s) to be updated'

          option :bootstrap_vault_json,
            :long        => '--bootstrap-vault-json VAULT_JSON',
            :description => 'A JSON string with the vault(s) and item(s) to be updated'

          option :bootstrap_vault_item,
            :long        => '--bootstrap-vault-item VAULT_ITEM',
            :description => 'A single vault and item to update as "vault:item"',
            :proc        => Proc.new { |i|
              (vault, item) = i.split(/:/)
              Chef::Config[:knife][:bootstrap_vault_item] ||= {}
              Chef::Config[:knife][:bootstrap_vault_item][vault] ||= []
              Chef::Config[:knife][:bootstrap_vault_item][vault].push(item)
              Chef::Config[:knife][:bootstrap_vault_item]
            }

          option :policy_name,
            :long         => "--policy-name POLICY_NAME",
            :description  => "Policyfile name to use (--policy-group must also be given)",
            :default      => nil

          option :policy_group,
            :long         => "--policy-group POLICY_GROUP",
            :description  => "Policy group name to use (--policy-name must also be given)",
            :default      => nil

          option :tags,
            :long => "--tags TAGS",
            :description => "Comma separated list of tags to apply to the node",
            :proc => lambda { |o| o.split(/[\s,]+/) },
            :default => []
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

      def load_correct_secret
        knife_secret_file = Chef::Config[:knife][:encrypted_data_bag_secret_file]
        knife_secret = Chef::Config[:knife][:encrypted_data_bag_secret]
        cli_secret_file = config[:encrypted_data_bag_secret_file]
        cli_secret = config[:encrypted_data_bag_secret]

        cli_secret_file = nil if cli_secret_file == knife_secret_file
        cli_secret = nil if cli_secret == knife_secret

        cli_secret_file = Chef::EncryptedDataBagItem.load_secret(cli_secret_file) if cli_secret_file != nil
        knife_secret_file = Chef::EncryptedDataBagItem.load_secret(knife_secret_file) if knife_secret_file != nil

        cli_secret_file || cli_secret || knife_secret_file || knife_secret
      end

      def render_template(template=nil)
        config[:secret] = load_correct_secret
        Erubis::Eruby.new(template).evaluate(bootstrap_context)
      end

      def bootstrap(proto=nil)
        if Chef::Config[:knife][:encrypted_data_bag_secret_file] || Chef::Config[:knife][:encrypted_data_bag_secret]
          warn_chef_config_secret_key
        end

        bootstrap_architecture = Chef::Config[:knife][:bootstrap_architecture]
        if bootstrap_architecture && ![:x86_64, :i386].include?(bootstrap_architecture.to_sym)
          raise "Valid values for the knife config :bootstrap_architecture are i386 or x86_64. Supplied value is #{bootstrap_architecture}"
        end
        if Chef::Config[:knife][:architecture]
          raise "Do not set :architecture in your knife config, use :bootstrap_architecture."
        end

        validate_name_args!

        # adding respond_to? so this works with pre 12.4 chef clients
        validate_options! if respond_to?(:validate_options!)

        @node_name = Array(@name_args).first
        # back compat--templates may use this setting:
        config[:server_name] = @node_name

        STDOUT.sync = STDERR.sync = true

        if Chef::VERSION.split('.').first.to_i == 11 && Chef::Config[:validation_key] && !File.exist?(File.expand_path(Chef::Config[:validation_key]))
          ui.error("Unable to find validation key. Please verify your configuration file for validation_key config value.")
          exit 1
        end

        if (defined?(chef_vault_handler) && chef_vault_handler.doing_chef_vault?) ||
            (Chef::Config[:validation_key] && !File.exist?(File.expand_path(Chef::Config[:validation_key])))

          unless locate_config_value(:chef_node_name)
            ui.error("You must pass a node name with -N when bootstrapping with user credentials")
            exit 1
          end

          client_builder.run

          if client_builder.respond_to?(:client)
            chef_vault_handler.run(client_builder.client)
          else
            chef_vault_handler.run(node_name: config[:chef_node_name])
          end

          bootstrap_context.client_pem = client_builder.client_path

        else
          ui.info("Doing old-style registration with the validation key at #{Chef::Config[:validation_key]}...")
          ui.info("Delete your validation key in order to use your user credentials instead")
          ui.info("")
        end

        wait_for_remote_response( config[:auth_timeout].to_i )

        set_target_architecture(bootstrap_architecture)

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

      # We allow the user to specify the desired architecture of Chef to install or we default
      # to whatever the target system is.  We assume that we are only bootstrapping 1 node at a time
      # so we don't need to worry about multipe responses from this command.
      def set_target_architecture(bootstrap_architecture)
        session_results = relay_winrm_command("echo %PROCESSOR_ARCHITECTURE%")
        if session_results.empty? || session_results[0].stdout.strip.empty?
          raise "Response to 'echo %PROCESSOR_ARCHITECTURE%' command was invalid: #{session_results}"
        end
        current_architecture = session_results[0].stdout.strip == "X86" ? :i386 : :x86_64

        if bootstrap_architecture.nil?
          architecture = current_architecture
        elsif bootstrap_architecture == :x86_64 && current_architecture == :i386
          raise "You specified bootstrap_architecture as x86_64 but the target machine is i386. A 64 bit program cannot run on a 32 bit machine."
        else
          architecture = bootstrap_architecture
        end

        # The windows install script wants i686, not i386
        architecture = :i686 if architecture == :i386
        Chef::Config[:knife][:architecture] = architecture
      end
    end
  end
end
