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

require 'chef/knife'
require 'chef/encrypted_data_bag_item'

class Chef
  class Knife
    module WinrmBase

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

        end
      end

    end
  end
end