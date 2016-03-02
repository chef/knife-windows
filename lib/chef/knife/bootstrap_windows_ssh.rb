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

require 'chef/knife/bootstrap_windows_base'

class Chef
  class Knife
    class BootstrapWindowsSsh < Bootstrap

      include Chef::Knife::BootstrapWindowsBase

      deps do
        require 'chef/knife/core/windows_bootstrap_context'
        require 'chef/json_compat'
        require 'tempfile'
        require 'highline'
        require 'net/ssh'
        require 'net/ssh/multi'
        Chef::Knife::Ssh.load_deps
      end

      banner "knife bootstrap windows ssh FQDN (options)"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key.strip }

      option :ssh_gateway,
        :short => "-G GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The ssh gateway",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway] = key }

      option :forward_agent,
        :short => "-A",
        :long => "--forward-agent",
        :description => "Enable SSH agent forwarding",
        :boolean => true

      option :identity_file,
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication. [DEPRECATED] Use --ssh-identity-file instead."

      option :ssh_identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--ssh-identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      # DEPR: Remove this option for the next release.
      option :host_key_verification,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default. [DEPRECATED] Use --host-key-verify option instead.",
        :boolean => true,
        :default => true,
        :proc => Proc.new { |key|
          Chef::Log.warn("[DEPRECATED] --host-key-verification option is deprecated. Use --host-key-verify option instead.")
          config[:host_key_verify] = key
        }

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      def run
        bootstrap
      end

      def run_command(command = '')
        ssh = Chef::Knife::Ssh.new
        ssh.name_args = [ server_name, command ]
        ssh.config[:ssh_user] = locate_config_value(:ssh_user)
        ssh.config[:ssh_password] = locate_config_value(:ssh_password)
        ssh.config[:ssh_port] = locate_config_value(:ssh_port)
        ssh.config[:ssh_gateway] =  locate_config_value(:ssh_gateway)
        ssh.config[:identity_file] = config[:identity_file]
        ssh.config[:ssh_identity_file] = config[:ssh_identity_file] || config[:identity_file]
        ssh.config[:forward_agent] = config[:forward_agent]
        ssh.config[:manual] = true
        ssh.config[:host_key_verify] = config[:host_key_verify]
        ssh.run
      end

    end
  end
end
