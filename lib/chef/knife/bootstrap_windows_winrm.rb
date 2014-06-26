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
        winrm.config[:suppress_auth_failure] = locate_config_value(:suppress_auth_failure)
        winrm.config[:returns] = nil
        winrm.run
      end

      protected

      def wait_for_remote_response(wait_max_minutes)
        wait_max_seconds = wait_max_minutes * 60
        retry_interval_seconds = 10
        retries_left = wait_max_seconds / retry_interval_seconds
        print(ui.color("\nWaiting for remote response before bootstrap", :magenta))
        wait_start_time = Time.now
        begin
          print(".")
          # Return status of the command is non-zero, typically nil,
          # for our simple echo command in cases where run_command
          # swallows the exception, such as 401's. Treat such cases
          # the same as the case where we encounter an exception.
          status = run_command("echo . & echo Response received.")
          raise RuntimeError, 'Command execution failed.' if status != 0
          ui.info(ui.color("Remote node responded after #{elapsed_time_in_minutes(wait_start_time)} minutes.", :magenta))
          return
        rescue
          retries_left -= 1
          if retries_left <= 0 || (elapsed_time_in_minutes(wait_start_time) > wait_max_minutes)
            ui.error("No response received from remote node after #{elapsed_time_in_minutes(wait_start_time)} minutes, giving up.")
            raise
          end
          print '.'
          sleep retry_interval_seconds
          retry
        end
      end

      def elapsed_time_in_minutes(start_time)
        ((Time.now - start_time) / 60).round(2)
      end
    end
  end
end

