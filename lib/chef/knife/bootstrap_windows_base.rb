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
require 'chef/knife/bootstrap'
require 'chef/encrypted_data_bag_item'
require 'chef/knife/knife_windows_base'
require 'chef/util/path_helper'

class Chef
  class Knife
    module BootstrapWindowsBase

      include Chef::Knife::KnifeWindowsBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'readline'
            require 'chef/json_compat'
          end

          option :chef_node_name,
            :short => "-N NAME",
            :long => "--node-name NAME",
            :description => "The Chef node name for your new node"

          option :prerelease,
            :long => "--prerelease",
            :description => "Install the pre-release chef gems"

          option :bootstrap_version,
            :long => "--bootstrap-version VERSION",
            :description => "The version of Chef to install",
            :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

          option :bootstrap_proxy,
            :long => "--bootstrap-proxy PROXY_URL",
            :description => "The proxy server for the node being bootstrapped",
            :proc => Proc.new { |p| Chef::Config[:knife][:bootstrap_proxy] = p }

          option :bootstrap_no_proxy,
            :long => "--bootstrap-no-proxy [NO_PROXY_URL|NO_PROXY_IP]",
            :description => "Do not proxy locations for the node being bootstrapped; this option is used internally by Opscode",
            :proc => Proc.new { |np| Chef::Config[:knife][:bootstrap_no_proxy] = np }

          option :bootstrap_install_command,
            :long        => "--bootstrap-install-command COMMANDS",
            :description => "Custom command to install chef-client",
            :proc        => Proc.new { |ic| Chef::Config[:knife][:bootstrap_install_command] = ic }

          option :bootstrap_template,
            :short => "-t TEMPLATE",
            :long => "--bootstrap-template TEMPLATE",
            :description => "Bootstrap Chef using a built-in or custom template. Set to the full path of an erb template or use one of the built-in templates."

          option :run_list,
            :short => "-r RUN_LIST",
            :long => "--run-list RUN_LIST",
            :description => "Comma separated list of roles/recipes to apply",
            :proc => lambda { |o| o.split(",") },
            :default => []

          option :hint,
            :long => "--hint HINT_NAME[=HINT_FILE]",
            :description => "Specify Ohai Hint to be set on the bootstrap target. Use multiple --hint options to specify multiple hints.",
            :proc => Proc.new { |h|
              Chef::Config[:knife][:hints] ||= Hash.new
              name, path = h.split("=")
              Chef::Config[:knife][:hints][name] = path ? Chef::JSONCompat.parse(::File.read(path)) : Hash.new
            }

          option :first_boot_attributes,
            :short => "-j JSON_ATTRIBS",
            :long => "--json-attributes",
            :description => "A JSON string to be added to the first run of chef-client",
            :proc => lambda { |o| JSON.parse(o) },
            :default => nil

          option :first_boot_attributes_from_file,
            :long => "--json-attribute-file FILE",
            :description => "A JSON file to be used to the first run of chef-client",
            :proc => lambda { |o| Chef::JSONCompat.parse(File.read(o)) },
            :default => nil

          # Mismatch between option 'encrypted_data_bag_secret' and it's long value '--secret' is by design for compatibility
          option :encrypted_data_bag_secret,
            :short => "-s SECRET",
            :long  => "--secret ",
            :description => "The secret key to use to decrypt data bag item values. Will be rendered on the node at c:/chef/encrypted_data_bag_secret and set in the rendered client config.",
            :default => false

          # Mismatch between option 'encrypted_data_bag_secret_file' and it's long value '--secret-file' is by design for compatibility
          option :encrypted_data_bag_secret_file,
            :long => "--secret-file SECRET_FILE",
            :description => "A file containing the secret key to use to encrypt data bag item values. Will be rendered on the node at c:/chef/encrypted_data_bag_secret and set in the rendered client config."

          option :auth_timeout,
            :long => "--auth-timeout MINUTES",
            :description => "The maximum time in minutes to wait to for authentication over the transport to the node to succeed. The default value is 2 minutes.",
            :default => 2

          option :node_ssl_verify_mode,
            :long        => "--node-ssl-verify-mode [peer|none]",
            :description => "Whether or not to verify the SSL cert for all HTTPS requests.",
            :proc        => Proc.new { |v|
              valid_values = ["none", "peer"]
              unless valid_values.include?(v)
                raise "Invalid value '#{v}' for --node-ssl-verify-mode. Valid values are: #{valid_values.join(", ")}"
              end
              v
            }

          option :node_verify_api_cert,
            :long        => "--[no-]node-verify-api-cert",
            :description => "Verify the SSL cert for HTTPS requests to the Chef server API.",
            :boolean     => true

          option :msi_url,
            :short => "-u URL",
            :long => "--msi-url URL",
            :description => "Location of the Chef Client MSI. The default templates will prefer to download from this location. The MSI will be downloaded from chef.io if not provided.",
            :default => ''

          option :install_as_service,
            :long => "--install-as-service",
            :description => "Install chef-client as a Windows service",
            :default => false

          option :bootstrap_vault_file,
          :long        => '--bootstrap-vault-file VAULT_FILE',
          :description => 'A JSON file with a list of vault(s) and item(s) to be updated'

          option :bootstrap_vault_json,
            :long        => '--bootstrap-vault-json VAULT_JSON',
            :description => 'A JSON string with the vault(s) and item(s) to be updated'

          option :bootstrap_vault_item,
            :long        => '--bootstrap-vault-item VAULT_ITEM',
            :description => 'A single vault and item to update as "vault:item"',
            :proc        => Proc.new { |i|
              (vault, item) = i.split(/:/)
              Chef::Config[:knife][:bootstrap_vault_item] ||= {}
              Chef::Config[:knife][:bootstrap_vault_item][vault] ||= []
              Chef::Config[:knife][:bootstrap_vault_item][vault].push(item)
              Chef::Config[:knife][:bootstrap_vault_item]
            }

          option :policy_name,
            :long         => "--policy-name POLICY_NAME",
            :description  => "Policyfile name to use (--policy-group must also be given)",
            :default      => nil

          option :policy_group,
            :long         => "--policy-group POLICY_GROUP",
            :description  => "Policy group name to use (--policy-name must also be given)",
            :default      => nil

          option :tags,
            :long => "--tags TAGS",
            :description => "Comma separated list of tags to apply to the node",
            :proc => lambda { |o| o.split(/[\s,]+/) },
            :default => []
        end
      end
    end
  end
end
