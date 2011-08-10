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

class Chef
  class Knife
    class BootstrapWindowsWinrm < Bootstrap

      include Chef::Knife::BootstrapWindowsBase

      deps do
        require 'chef/knife/core/windows_bootstrap_context'
        require 'chef/json_compat'
        require 'tempfile'
        Chef::Knife::Winrm.load_deps
      end

      banner "knife bootstrap windows winrm FQDN (options)"

      option :winrm_user,
        :short => "-x USERNAME",
        :long => "--winrm-user USERNAME",
        :description => "The WinRM username",
        :default => "Administrator",
        :proc => Proc.new { |key| Chef::Config[:knife][:winrm_user] = key }

      option :winrm_password,
        :short => "-P PASSWORD",
        :long => "--winrm-password PASSWORD",
        :description => "The WinRM password",
        :proc => Proc.new { |key| Chef::Config[:knife][:winrm_password] = key }

      option :winrm_port,
        :short => "-p PORT",
        :long => "--winrm-port PORT",
        :description => "The WinRM port, by default this is 5985",
        :default => "5985",
        :proc => Proc.new { |key| Chef::Config[:knife][:winrm_port] = key }

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :winrm_transport,
        :short => "-t TRANSPORT",
        :long => "--winrm-transport TRANSPORT",
        :description => "The WinRM transport type.  valid choices are [ssl, plaintext]",
        :default => 'plaintext',
        :proc => Proc.new { |transport| Chef::Config[:knife][:winrm_transport] = transport }

      option :kerberos_keytab_file,
        :short => "-i KEYTAB_FILE",
        :long => "--keytab-file KEYTAB_FILE",
        :description => "The Kerberos keytab file used for authentication",
        :proc => Proc.new { |keytab| Chef::Config[:knife][:kerberos_keytab_file] = keytab }

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

      def run
        bootstrap
      end

      def run_command(command = '')
        winrm = Chef::Knife::Winrm.new
        winrm.name_args = [ server_name, command ]
        winrm.config[:winrm_user] = locate_config_value(:winrm_user)
        winrm.config[:winrm_password] = locate_config_value(:winrm_password)
        winrm.config[:winrm_transport] = locate_config_value(:winrm_transport)
        winrm.config[:kerberos_keytab_file] = Chef::Config[:knife][:kerberos_keytab_file] if Chef::Config[:knife][:kerberos_keytab_file]
        winrm.config[:kerberos_realm] = Chef::Config[:knife][:kerberos_realm] if Chef::Config[:knife][:kerberos_realm]
        winrm.config[:kerberos_service] = Chef::Config[:knife][:kerberos_service] if Chef::Config[:knife][:kerberos_service]
        winrm.config[:ca_trust_file] = Chef::Config[:knife][:ca_trust_file] if Chef::Config[:knife][:ca_trust_file]
        winrm.config[:manual] = true
        winrm.config[:winrm_port] = locate_config_value(:winrm_port)
        winrm
      end

    end
  end
end

