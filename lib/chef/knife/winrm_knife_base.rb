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

      FAILED_BASIC_HINT ||= "Hint: Please check winrm configuration 'winrm get winrm/config/service' AllowUnencrypted flag on remote server."
      FAILED_NOT_BASIC_HINT ||= <<-eos.gsub /^\s+/, ""
        Hint: Make sure to prefix domain usernames with the correct domain name.
        Hint: Local user names should be prefixed with computer name or IP address.
        EXAMPLE: my_domain\\user_namer
      eos

      def self.included(includer)
        includer.class_eval do

          @@ssl_warning_given = false

          include Chef::Knife::WinrmBase
          include Chef::Knife::WinrmSharedOptions
          include Chef::Knife::KnifeWindowsBase

          def validate_winrm_options!
            winrm_auth_protocol = locate_config_value(:winrm_authentication_protocol)

            if ! Chef::Knife::WinrmBase::WINRM_AUTH_PROTOCOL_LIST.include?(winrm_auth_protocol)
              ui.error "Invalid value '#{winrm_auth_protocol}' for --winrm-authentication-protocol option."
              ui.info "Valid values are #{Chef::Knife::WinrmBase::WINRM_AUTH_PROTOCOL_LIST.join(",")}."
              exit 1
            end

            warn_no_ssl_peer_verification if resolve_no_ssl_peer_verification
          end

          #Overrides Chef::Knife#configure_session, as that code is tied to the SSH implementation
          #Tracked by Issue # 3042 / https://github.com/chef/chef/issues/3042
          def configure_session
            validate_winrm_options!
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

          # TODO: Copied from Knife::Core:GenericPresenter. Should be extracted
          def extract_nested_value(data, nested_value_spec)
            nested_value_spec.split(".").each do |attr|
              if data.nil?
                nil # don't get no method error on nil
              elsif data.respond_to?(attr.to_sym)
                data = data.send(attr.to_sym)
              elsif data.respond_to?(:[])
                data = data[attr]
              else
                data = begin
                         data.send(attr.to_sym)
                       rescue NoMethodError
                         nil
                       end
              end
            end
            ( !data.kind_of?(Array) && data.respond_to?(:to_hash) ) ? data.to_hash : data
          end

          def run_command(command = '')
            relay_winrm_command(command)

            check_for_errors!

            # Knife seems to ignore the return value of this method,
            # so we exit to force the process exit code for this
            # subcommand if returns is set
            exit @exit_code if @exit_code && @exit_code != 0
            0
          end

          def relay_winrm_command(command)
            Chef::Log.debug(command)
            @winrm_sessions.each do |s|
              begin
                s.relay_command(command)
              rescue WinRM::WinRMHTTPTransportError, WinRM::WinRMAuthorizationError => e
                if authorization_error?(e)
                  if ! config[:suppress_auth_failure]
                    # Display errors if the caller hasn't opted to retry
                    ui.error "Failed to authenticate to #{s.host} as #{locate_config_value(:winrm_user)}"
                    ui.info "Response: #{e.message}"
                    ui.info get_failed_authentication_hint
                    raise e
                  end
                  @exit_code = 401
                else
                  raise e
                end
              end
            end
          end

          private

          def get_failed_authentication_hint
            if @session_opts[:basic_auth_only]
              FAILED_BASIC_HINT
            else
              FAILED_NOT_BASIC_HINT
            end
          end

          def authorization_error?(exception)
            exception.is_a?(WinRM::WinRMAuthorizationError) ||
              exception.message =~ /401/
          end

          def check_for_errors!
            @winrm_sessions.each do |session|
              session_exit_code = session.exit_code
              unless success_return_codes.include? session_exit_code.to_i
                @exit_code = session_exit_code.to_i
                ui.error "Failed to execute command on #{session.host} return code #{session_exit_code}"
              end
            end
          end

          def success_return_codes
            #Redundant if the CLI options parsing occurs
            return [0] unless config[:returns]
            return @success_return_codes ||= config[:returns].split(',').collect {|item| item.to_i}
          end

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
              no_ssl_peer_verification: resolve_no_ssl_peer_verification,
              ssl_peer_fingerprint: resolve_ssl_peer_fingerprint
            }

            if @session_opts[:user] and (not @session_opts[:password])
              @session_opts[:password] = Chef::Config[:knife][:winrm_password] = config[:winrm_password] = get_password
            end

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
            elsif transport != :ssl && negotiate_auth?
              transport = :negotiate
            end

            transport
          end

          def resolve_no_ssl_peer_verification
            locate_config_value(:ca_trust_file).nil? && config[:winrm_ssl_verify_mode] == :verify_none && resolve_winrm_transport == :ssl
          end

          def resolve_ssl_peer_fingerprint
            locate_config_value(:ssl_peer_fingerprint)
          end

          def resolve_winrm_disable_sspi
            resolve_winrm_transport != :negotiate
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
