#
# Author:: Steven Murawski (<smurawski@chef.io)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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
require 'chef/knife/winrm_base'
require 'chef/knife/winrm_shared_options'

class Chef
  class Knife
    module WinrmCommandSharedFunctions
      def self.included(includer)
        includer.class_eval do

          @@ssl_warning_given = false

          include Chef::Knife::WinrmBase
          include Chef::Knife::WinrmSharedOptions

          #Overrides Chef::Knife#configure_session, as that code is tied to the SSH implementation
          #Tracked by Issue # 3042 / https://github.com/chef/chef/issues/3042
          def configure_session
            resolve_session_options
            resolve_target_nodes
            session_from_list
          end

          def resolve_target_nodes
            @list = case config[:manual]
                   when true
                     @name_args[0].split(" ")
                   when false
                     r = Array.new
                     q = Chef::Search::Query.new
                     @action_nodes = q.search(:node, @name_args[0])[0]
                     @action_nodes.each do |item|
                       i = extract_nested_value(item, config[:attribute])
                       r.push(i) unless i.nil?
                     end
                     r
                   end
             if @list.length == 0
              if @action_nodes.length == 0
                ui.fatal("No nodes returned from search!")
              else
                ui.fatal("#{@action_nodes.length} #{@action_nodes.length > 1 ? "nodes":"node"} found, " +
                         "but does not have the required attribute (#{config[:attribute]}) to establish the connection. " +
                         "Try setting another attribute to open the connection using --attribute.")
              end
              exit 10
            end
          end

          def validate_password
            if @session_opts[:user] and (not @session_opts[:password])
              @session_opts[:password] = Chef::Config[:knife][:winrm_password] = config[:winrm_password] = get_password
            end
          end

          private

          def session_from_list
            @list.each do |item|
              Chef::Log.debug("Adding #{item}")
              @session_opts[:host] = item
              create_winrm_session(@session_opts)
            end
          end

          def create_winrm_session(options={})
            session = Chef::Knife::WinrmSession.new(options)
            @winrm_sessions ||= []
            @winrm_sessions.push(session)
          end

          def resolve_session_options
            resolve_winrm_basic_options
            resolve_winrm_auth_settings
            resolve_winrm_kerberos_options
            resolve_winrm_transport_options
            resolve_winrm_ssl_options
          end

          def resolve_winrm_basic_options
            @session_opts = {}
            @session_opts[:user] = locate_config_value(:winrm_user)
            @session_opts[:password] = locate_config_value(:winrm_password)

            # set default winrm_port = 5986 for ssl transport
            # set default winrm_port = 5985 for plaintext transport
            case locate_config_value(:winrm_transport)
            when 'ssl'
              Chef::Config[:knife][:winrm_port] = "5986"
            else
              Chef::Config[:knife][:winrm_port] = "5985"
            end
            @session_opts[:port] = locate_config_value(:winrm_port)
            #30 min (Default) OperationTimeout for long bootstraps fix for KNIFE_WINDOWS-8
            @session_opts[:operation_timeout] = locate_config_value(:session_timeout).to_i * 60 if locate_config_value(:session_timeout)
          end

          def resolve_winrm_kerberos_options
            if config.keys.any? {|k| k.to_s =~ /kerberos/ }
              @session_opts[:transport] = :kerberos
              @session_opts[:keytab] = locate_config_value(:kerberos_keytab_file) if locate_config_value(:kerberos_keytab_file)
              @session_opts[:realm] = locate_config_value(:kerberos_realm) if locate_config_value(:kerberos_realm)
              @session_opts[:service] = locate_config_value(:kerberos_service) if locate_config_value(:kerberos_service)
            end
          end

          def resolve_winrm_transport_options
            @session_opts[:disable_sspi] = true
            @session_opts[:transport] = locate_config_value(:winrm_transport).to_sym unless @session_opts[:transport] == :kerberos
            if negotiate_auth? && @session_opts[:transport] == :ssl
                Chef::Log.debug("Trying WinRM communication with negotiate authentication and :ssl transport")
            elsif use_windows_native_auth?
              load_windows_specific_gems
              @session_opts[:transport] = :sspinegotiate
              @session_opts[:disable_sspi] = false
            elsif negotiate_auth? && !Chef::Platform.windows?
              ui.warn "The '--winrm-authentication-protocol = negotiate' with 'plaintext' transport is only supported when this tool is invoked from a Windows-based system."
              ui.info "Try '--winrm-authentication-protocol = basic'"
              exit 1
            end
          end

          def resolve_winrm_ssl_options
            @session_opts[:ca_trust_path] = locate_config_value(:ca_trust_file) if locate_config_value(:ca_trust_file)
            @session_opts[:no_ssl_peer_verification] = no_ssl_peer_verification?(@session_opts[:ca_trust_path])
            warn_no_ssl_peer_verification if @session_opts[:no_ssl_peer_verification]
          end

          def resolve_winrm_auth_settings
            winrm_auth_protocol = locate_config_value(:winrm_authentication_protocol)
            if ! Chef::Knife::WinrmBase::WINRM_AUTH_PROTOCOL_LIST.include?(winrm_auth_protocol)
              ui.error "Invalid value '#{winrm_auth_protocol}' for --winrm-authentication-protocol option."
              ui.info "Valid values are #{Chef::Knife::WinrmBase::WINRM_AUTH_PROTOCOL_LIST.join(",")}."
              exit 1
            end

            if winrm_auth_protocol == "basic"
              @session_opts[:basic_auth_only] = true
            else
              @session_opts[:basic_auth_only] = false
            end
          end

          def no_ssl_peer_verification?(ca_trust_path)
            ca_trust_path.nil? && (config[:winrm_ssl_verify_mode] == :verify_none)
          end

          def use_windows_native_auth?
           Chef::Platform.windows? && @session_opts[:transport] != :ssl && negotiate_auth?
          end

          def load_windows_specific_gems
            require 'winrm-s'
            Chef::Log.debug("Applied 'winrm-s' monkey patch and trying WinRM communication with 'sspinegotiate'")
          end

          def get_password
            @password ||= ui.ask("Enter your password: ") { |q| q.echo = false }
          end

          # returns true if winrm_authentication_protocol is 'negotiate'
          def negotiate_auth?
            locate_config_value(:winrm_authentication_protocol) == "negotiate"
          end

          def warn_no_ssl_peer_verification
            if ! @@ssl_warning_given
              @@ssl_warning_given = true
              ui.warn(<<-WARN)
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
SSL validation of HTTPS requests for the WinRM transport is disabled. HTTPS WinRM
connections are still encrypted, but knife is not able to detect forged replies
or spoofing attacks.

To fix this issue add an entry like this to your knife configuration file:

```
  # Verify all WinRM HTTPS connections (default, recommended)
  knife[:winrm_ssl_verify_mode] = :verify_peer
```
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
WARN
                end
              end

        end
      end
    end
  end
end
