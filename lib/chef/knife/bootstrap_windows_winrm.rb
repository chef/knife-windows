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
require 'chef/knife/winrm_knife_base'


class Chef
  class Knife
    class BootstrapWindowsWinrm < Bootstrap

      include Chef::Knife::BootstrapWindowsBase
      include Chef::Knife::WinrmBase
      include Chef::Knife::WinrmCommandSharedFunctions


      deps do
        require 'chef/knife/core/windows_bootstrap_context'
        require 'chef/json_compat'
        require 'tempfile'
        Chef::Knife::Winrm.load_deps
      end

      banner "knife bootstrap windows winrm FQDN (options)"

      def run
        if (Chef::Config[:validation_key] && !File.exist?(File.expand_path(Chef::Config[:validation_key])))

          if !negotiate_auth? && !(locate_config_value(:winrm_transport) == 'ssl')
            ui.error("Validatorless bootstrap only supported with negotiate authentication protocol and ssl/plaintext transport")
            exit 1
          elsif !(Chef::Platform.windows?) && negotiate_auth?
            ui.error("Negotiate protocol with plaintext transport is only supported when this tool is invoked from windows based system")
            exit 1
          end

        end
        bootstrap
      end


      def run_command(command = '')
        winrm = Chef::Knife::Winrm.new
        winrm.name_args = [ server_name, command ]
        winrm.config[:winrm_user] = locate_config_value(:winrm_user)
        winrm.config[:winrm_password] = locate_config_value(:winrm_password)
        winrm.config[:winrm_transport] = locate_config_value(:winrm_transport)
        winrm.config[:winrm_ssl_verify_mode] = locate_config_value(:winrm_ssl_verify_mode)
        winrm.config[:kerberos_keytab_file] = locate_config_value(:kerberos_keytab_file) if locate_config_value(:kerberos_keytab_file)
        winrm.config[:kerberos_realm] = locate_config_value(:kerberos_realm) if locate_config_value(:kerberos_realm)
        winrm.config[:kerberos_service] = locate_config_value(:kerberos_service) if locate_config_value(:kerberos_service)
        winrm.config[:ca_trust_file] = locate_config_value(:ca_trust_file) if locate_config_value(:ca_trust_file)
        winrm.config[:manual] = true
        winrm.config[:winrm_port] = locate_config_value(:winrm_port)
        winrm.config[:suppress_auth_failure] = true

        #If you turn off the return flag, then winrm.run won't atually check and
        #return the error
        #codes.  Otherwise, it ignores the return value of the server call.
        winrm.config[:returns] = "0"
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
