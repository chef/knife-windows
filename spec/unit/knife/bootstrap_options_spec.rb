#
# Author:: Kartik Null Cating-Subramanian(<ksubramanian@chef.io>)
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

require 'spec_helper'

describe Chef::Knife::Bootstrap, :chef_gte_12_6_only do
  before(:all) do
    Chef::Config.reset
  end

  let(:bootstrap) { Chef::Knife::Bootstrap.new }
  let(:win_bootstrap) { nil }
  let(:opt_map) { {} }
  let(:ref_ignore) { [] }
  let(:win_ignore) { [] }

  def compare_property(sym)
    win_bootstrap.options.each do |win_key, win_val|
      unless win_ignore.include?(win_key) || opt_map.include?(win_key) then
        actual = win_val[sym]
        expected = bootstrap.options[win_key][sym]
        expect(actual).to eq(expected),
          "#{win_key} flag's #{sym} property doesn't match

expected: #{expected}
     got: #{actual}"
      end
    end
  end

  shared_examples 'compare_options' do
    it 'contains the option flags' do
      opt_map.default_proc = proc { |map, key| key }
      filtered_keys = (win_bootstrap.options.keys - win_ignore).map! { |key| opt_map[key] }

      expect(filtered_keys).to match_array(bootstrap.options.keys - ref_ignore)
    end

    it 'uses the same long-name' do
      compare_property(:long)
    end

    it 'uses the same short-name' do
      compare_property(:short)
    end

    it 'uses the same description' do
      compare_property(:description)
    end

    it 'uses the same default value' do
      compare_property(:default)
    end
  end

  context 'when compared to BootstrapWindowsWinrm' do
    let(:win_bootstrap) { Chef::Knife::BootstrapWindowsWinrm.new }

    # opt_map: Hash of symbols in windows mapping to symbols in core.  Name checks are
    #   ignored for these.
    let(:opt_map) { {
      :msi_url => :bootstrap_url,
      :encrypted_data_bag_secret => :secret,
      :encrypted_data_bag_secret_file => :secret_file,
      :winrm_user => :ssh_user,
      :winrm_password => :ssh_password,
      :winrm_port => :ssh_port,
      :winrm_ssl_verify_mode => :host_key_verify,
      :bootstrap_install_command => :bootstrap_install_command,
    }}

    # ref_ignore: Options in core that are not implemented here.
    let(:ref_ignore) { [
      # These are irrelevant to WinRM.
      :bootstrap_curl_options,
      :bootstrap_wget_options,
      :forward_agent,
      :preserve_home,
      :ssh_gateway,
      :use_sudo,
      :use_sudo_password,
      :encrypt, # irrelevant during bootstrap
      :identity_file,
      :ssh_identity_file,
      :fips, #until chef 12.7 is released
    ]}

    # win_ignore: Options in windows that aren't relevant to core.
    let(:win_ignore) { [
      :attribute,
      :auth_timeout,
      :ca_trust_file,
      :install_as_service,
      :kerberos_keytab_file,
      :kerberos_realm,
      :kerberos_service,
      :manual,
      :session_timeout,
      :ssl_peer_fingerprint,
      :winrm_authentication_protocol,
      :winrm_transport,
      :fips, #until chef 12.7 is released
    ] }

    include_examples 'compare_options'
  end

  context 'when compared to BootstrapWindowsSsh' do
    let(:win_bootstrap) { Chef::Knife::BootstrapWindowsSsh.new }

    # opt_map: Hash of symbols in windows mapping to symbols in core.  Name checks are
    #   ignored for these.
    let(:opt_map) { {
      :msi_url => :bootstrap_url,
      :encrypted_data_bag_secret => :secret,
      :encrypted_data_bag_secret_file => :secret_file,
      :bootstrap_install_command => :bootstrap_install_command,
    }}
    # ref_ignore: Options in core that are not implemented here.
    let(:ref_ignore) { [
      :bootstrap_curl_options,
      :bootstrap_wget_options,
      :preserve_home,
      :use_sudo,
      :use_sudo_password,
      :encrypt, # irrelevant during bootstrap
      :fips, #until chef 12.7 is released
    ]}
    # win_ignore: Options in windows that aren't relevant to core.
    let(:win_ignore) { [
      :auth_timeout,
      :install_as_service,
      :host_key_verification,  # Deprecated - remove this when the flag is removed.
      :fips, #until chef 12.7 is released
    ] }

    include_examples 'compare_options'
  end

end
