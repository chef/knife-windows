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

require 'chef/knife'
require 'chef/encrypted_data_bag_item'
require 'kconv'

class Chef
  class Knife
    module WinrmBase

      # It includes supported WinRM authentication protocol.
      WINRM_AUTH_PROTOCOL_LIST ||= %w{basic negotiate kerberos}

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'readline'
            require 'chef/json_compat'
          end

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

          option :winrm_shell,
            :long => "--winrm-shell SHELL",
            :description => "The WinRM shell type. Valid choices are [cmd, powershell, elevated]. 'elevated' runs powershell in a scheduled task",
            :default => :cmd,
            :proc => Proc.new { |shell| shell.to_sym }

          option :winrm_transport,
            :short => "-w TRANSPORT",
            :long => "--winrm-transport TRANSPORT",
            :description => "The WinRM transport type. Valid choices are [ssl, plaintext]",
            :default => 'plaintext',
            :proc => Proc.new { |transport| Chef::Config[:knife][:winrm_port] = '5986' if transport == 'ssl'
                                Chef::Config[:knife][:winrm_transport] = transport }

          option :winrm_port,
            :short => "-p PORT",
            :long => "--winrm-port PORT",
            :description => "The WinRM port, by default this is '5985' for 'plaintext' and '5986' for 'ssl' winrm transport",
            :default => '5985',
            :proc => Proc.new { |key| Chef::Config[:knife][:winrm_port] = key }

          option :kerberos_keytab_file,
            :short => "-T KEYTAB_FILE",
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

          option :winrm_ssl_verify_mode,
            :long => "--winrm-ssl-verify-mode SSL_VERIFY_MODE",
            :description => "The WinRM peer verification mode. Valid choices are [verify_peer, verify_none]",
            :default => :verify_peer,
            :proc => Proc.new { |verify_mode| verify_mode.to_sym }

          option :ssl_peer_fingerprint,
            :long => "--ssl-peer-fingerprint FINGERPRINT",
            :description => "ssl Cert Fingerprint to bypass normal cert chain checks"

          option :winrm_authentication_protocol,
            :long => "--winrm-authentication-protocol AUTHENTICATION_PROTOCOL",
            :description => "The authentication protocol used during WinRM communication. The supported protocols are #{WINRM_AUTH_PROTOCOL_LIST.join(',')}. Default is 'negotiate'.",
            :default => "negotiate",
            :proc => Proc.new { |protocol| Chef::Config[:knife][:winrm_authentication_protocol] = protocol }

          option :session_timeout,
            :long => "--session-timeout Minutes",
            :description => "The timeout for the client for the maximum length of the WinRM session",
            :default => 30

          option :winrm_codepage,
            :long => "--winrm-codepage Codepage",
            :description => "The codepage to use for the winrm cmd shell",
            :default => 65001
        end
      end
    end
  end
end
