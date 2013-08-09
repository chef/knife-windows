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
require 'chef/knife/winrm'
require 'chef/knife/winrm_base'
require 'chef/knife/bootstrap'

class Chef
  class Knife
    class BootstrapWindowsWinrm < Bootstrap

      include Chef::Knife::BootstrapWindowsBase
      include Chef::Knife::WinrmBase

      deps do
        require 'chef/knife/core/windows_bootstrap_context'
        require 'chef/json_compat'
        require 'tempfile'
        Chef::Knife::Winrm.load_deps
      end

      banner "knife bootstrap windows winrm FQDN (options)"

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
        winrm.run
      end

    end
  end
end

