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
require 'chef/knife/knife_windows_base'

class Chef
  class Knife
    module WinrmCommandSharedFunctions
      def self.included(includer)
        includer.class_eval do

          @@ssl_warning_given = false

          include Chef::Knife::WinrmBase
          include Chef::Knife::WinrmSharedOptions
          include Chef::Knife::KnifeWindowsBase

          def validate_options!
            winrm_auth_protocol = locate_config_value(:winrm_authentication_protocol)

            if ! Chef::Knife::WinrmBase::WINRM_AUTH_PROTOCOL_LIST.include?(winrm_auth_protocol)
              ui.error "Invalid value '#{winrm_auth_protocol}' for --winrm-authentication-protocol option."
              ui.info "Valid values are #{Chef::Knife::WinrmBase::WINRM_AUTH_PROTOCOL_LIST.join(",")}."
              exit 1
            end

            if negotiate_auth? && !Chef::Platform.windows? && !(locate_config_value(:winrm_transport) == 'ssl')
              ui.warn <<-eos.gsub /^\s+/, ""
                You are using '--winrm-authentication-protocol negotiate' with 
                '--winrm-transport plaintext' on a non-Windows system which results in
                unencrypted traffic. To avoid this warning and secure communication,
                use '--winrm-transport ssl' instead of the plaintext transport,
                or execute this command from a Windows system which enables encrypted
                communication over plaintext with the negotiate authentication protocol.
              eos
            end

            warn_no_ssl_peer_verification if resolve_no_ssl_peer_verification
          end

          #Overrides Chef::Knife#configure_session, as that code is tied to the SSH implementation
          #Tracked by Issue # 3042 / https://github.com/chef/chef/issues/3042
          def configure_session
            validate_options!
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
            @session_opts = {
              user: resolve_winrm_user,
              password: locate_config_value(:winrm_password),
              port: locate_config_value(:winrm_port),
              operation_timeout: resolve_winrm_session_timeout,
              basic_auth_only: resolve_winrm_basic_auth,
              disable_sspi: resolve_winrm_disable_sspi,
              transport: resolve_winrm_transport,
              no_ssl_peer_verification: resolve_no_ssl_peer_verification
            }
            if @session_opts[:transport] == :kerberos
              @session_opts.merge!(resolve_winrm_kerberos_options)
            end
            @session_opts[:ca_trust_path] = locate_config_value(:ca_trust_file) if locate_config_value(:ca_trust_file)
          end

          def resolve_winrm_user
            user = locate_config_value(:winrm_user)
            
            # Prefixing with '.\' when using negotiate
            # to auth user against local machine domain
            if resolve_winrm_basic_auth ||
              resolve_winrm_transport == :kerberos ||
              user.include?("\\") ||
              user.include?("@")
              user
            else
              ".\\#{user}"
            end
          end

          def resolve_winrm_session_timeout
            #30 min (Default) OperationTimeout for long bootstraps fix for KNIFE_WINDOWS-8
            locate_config_value(:session_timeout).to_i * 60 if locate_config_value(:session_timeout)
          end

          def resolve_winrm_basic_auth
            locate_config_value(:winrm_authentication_protocol) == "basic"
          end

          def resolve_winrm_kerberos_options
            kerberos_opts = {}
            kerberos_opts[:keytab] = locate_config_value(:kerberos_keytab_file) if locate_config_value(:kerberos_keytab_file)
            kerberos_opts[:realm] = locate_config_value(:kerberos_realm) if locate_config_value(:kerberos_realm)
            kerberos_opts[:service] = locate_config_value(:kerberos_service) if locate_config_value(:kerberos_service)
            kerberos_opts
          end

          def resolve_winrm_transport
            transport = locate_config_value(:winrm_transport).to_sym
            if config.any? {|k,v| k.to_s =~ /kerberos/ && !v.nil? }
              transport = :kerberos
            elsif Chef::Platform.windows? && transport != :ssl && negotiate_auth?
              transport = :sspinegotiate
            end

            transport
          end

          def resolve_no_ssl_peer_verification
            locate_config_value(:ca_trust_file).nil? && config[:winrm_ssl_verify_mode] == :verify_none && resolve_winrm_transport == :ssl
          end

          def resolve_winrm_disable_sspi
            !Chef::Platform.windows? || resolve_winrm_transport == :ssl || !negotiate_auth?
          end

          def get_password
            @password ||= ui.ask("Enter your password: ") { |q| q.echo = false }
          end

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
