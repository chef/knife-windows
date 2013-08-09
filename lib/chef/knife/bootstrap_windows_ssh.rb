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

require 'chef/knife/bootstrap_windows_base'
# Avoid NameError: uninitialized constant Net::SSH::Service::Forward::UNIXServer
# http://stackoverflow.com/questions/11581019/netsshserviceforwardunixserver
Net::SSH::Service::Forward::UNIXServer = nil

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
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }
        
      option :ssh_gateway,
        :short => "-G GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The ssh gateway",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway] = key }

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :host_key_verification,
        :long => "--[no-]host-key-verification",
        :description => "Disable host key verification",
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
        ssh.config[:manual] = true
        ssh.config[:host_key_verify] = config[:host_key_verify]
        ssh.run
      end

    end
  end
end
