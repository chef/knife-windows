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

require 'chef/knife/bootstrap'

class Chef
  class Knife
    class WinrmBootstrap < Chef::Knife::Bootstrap

      banner "knife winrm bootstrap FQDN [RUN LIST...] (options)"

      option :winrm_user,
        :short => "-x USERNAME",
        :long => "--winrm-user USERNAME",
        :description => "The WinRM username"

      option :winrm_password,
        :short => "-P PASSWORD",
        :long => "--winrm-password PASSWORD",
        :description => "The WinRM password"

      option :winrm_port,
        :short => "-p PORT",
        :long => "--winrm-port PORT",
        :description => "The WinRM port",
        :default => "80",
        :proc => Proc.new { |key| Chef::Config[:knife][:winrm_port] = key }

      option :winrm_transport,
        :short => "-t TRANSPORT",
        :long => "--winrm-transport TRANSPORT",
        :description => "The WinRM transport type: ssl, or plaintext",
        :default => 'plaintext',
        :proc => Proc.new { |transport| Chef::Config[:knife][:winrm_transport] = transport }

      option :keytab_file,
        :short => "-i KEYTAB_FILE",
        :long => "--keytab-file KEYTAB_FILE",
        :description => "The Kerberos keytab file used for authentication",
        :proc => Proc.new { |keytab| Chef::Config[:knife][:keytab_file] = keytab }

      option :kerberos_realm,
        :short => "-R KERBEROS_REALM",
        :long => "--kerberos-realm KERBEROS_REALM",
        :description => "The Kerberos realm used for authentication",
        :proc => Proc.new { |realm| Chef::Config[:knife][:kerberos_realm] = realm }

      option :kerberos_service,
        :short => "-S KERBEROS_SERVICE",
        :long => "--kerberos-service KERBEROS_SERVICE",
        :description => "The Kerberos service used for authentication",
        :proc => Proc.new { |service| Chef::Config[:knife][:kerberos_service] = service }

      option :ca_trust_file,
        :short => "-f CA_TRUST_FILE",
        :long => "--ca-trust-file CA_TRUST_FILE",
        :description => "The Certificate Authority (CA) trust file used for SSL transport",
        :proc => Proc.new { |trust| Chef::Config[:knife][:ca_trust_file] = trust }

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :default => "windows-shell"

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
        end

        template = Array(bootstrap_files).find do |bootstrap_template|
          Chef::Log.debug("Looking for bootstrap template in #{File.dirname(bootstrap_template)}")
          File.exists?(bootstrap_template)
        end

        unless template
          Chef::Log.info("Can not find bootstrap definition for #{config[:distro]}")
          raise Errno::ENOENT
        end

        Chef::Log.debug("Found bootstrap template in #{File.dirname(template)}")
        
        IO.read(template).chomp
      end

      def run 
        require 'highline'

        validate_name_args!

        $stdout.sync = true

        Chef::Log.info("Bootstrapping Chef on #{h.color(config[:server_name], :bold)}")

        knife_winrm.load_late_dependencies

        # create a bootstrap.bat file on the node
        # we have to run the remote commands in 2047 char chunks
        create_bootstrap_bat_command do |command_chunk, chunk_num|
          knife_winrm("echo \"Rendering bootstrap.bat chunk #{chunk_num}\" && #{command_chunk}").run
        end

        # execute the bootstrap.bat file
        knife_winrm(bootstrap_command).run
      end

      def knife_winrm(command = '')
        winrm = Chef::Knife::Winrm.new
        winrm.name_args = [ server_name, command ]
        winrm.config[:winrm_user] = config[:winrm_user] 
        winrm.config[:winrm_password] = config[:winrm_password]
        winrm.config[:winrm_transport] = config[:winrm_transport]
        winrm.config[:kerberos_keytab_file] = config[:kerberos_keytab_file] if config[:kerberos_keytab_file]
        winrm.config[:kerberos_realm] = config[:kerberos_realm] if config[:kerberos_realm]
        winrm.config[:kerberos_service] = config[:kerberos_service] if config[:kerberos_service]
        winrm.config[:ca_trust_file] = config[:ca_trust_file] if config[:ca_trust_file]
        winrm.config[:manual] = true
        winrm
      end

      def bootstrap_command
        @bootstrap_command ||= "cmd /C #{bootstrap_bat_file}"
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

      def load_late_dependencies
        super
        require 'chef/knife/winrm'
      end
    end
  end
end

