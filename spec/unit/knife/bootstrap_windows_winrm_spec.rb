#
# Author:: Adam Edwards(<adamed@chef.io>)
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
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
require 'winrm/output'

Chef::Knife::Winrm.load_deps

describe Chef::Knife::BootstrapWindowsWinrm do
  before do
    Chef::Config.reset
    bootstrap.config[:run_list] = []
    allow(bootstrap).to receive(:validate_options!).and_return(nil)
    allow(bootstrap).to receive(:sleep).and_return(10)
    allow(Chef::Knife::WinrmSession).to receive(:new).and_return(session)
    allow(File).to receive(:exist?).with(anything).and_call_original
    allow(File).to receive(:exist?).with(File.expand_path(Chef::Config[:validation_key])).and_return(true)
  end

  after do
    allow(bootstrap).to receive(:sleep).and_return(10)
  end

  let(:session_opts) do
    {
      user: "Administrator",
      password: "testpassword",
      port: "5986",
      transport: :ssl,
      host: "localhost"
    }
  end
  let(:bootstrap) { Chef::Knife::BootstrapWindowsWinrm.new(['winrm', '-d', 'windows-chef-client-msi',  '-x', session_opts[:user], '-P', session_opts[:password], session_opts[:host]]) }
  let(:session) { Chef::Knife::WinrmSession.new(session_opts) }
  let(:arch_session_result) {
    o = WinRM::Output.new
    o << {stdout: "X86\r\n"}
    o
  }
  let(:arch_session_results) { [arch_session_result] }
  let(:initial_fail_count) { 4 }

  context "knife secret-file && knife secret options are passed" do
    before do
      Chef::Config.reset
      Chef::Config[:knife][:encrypted_data_bag_secret_file] = "/tmp/encrypted_data_bag_secret"
      Chef::Config[:knife][:encrypted_data_bag_secret] = "data_bag_secret_key_passed_under_knife_secret_option"
    end
    it "gives preference to secret key passed under knife's secret-file option" do
      allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
        Chef::Config[:knife][:encrypted_data_bag_secret_file]).
        and_return("data_bag_secret_key_passed_under_knife_secret_file_option")
      expect(bootstrap.load_correct_secret).to eq(
        "data_bag_secret_key_passed_under_knife_secret_file_option")
    end
  end

  context "cli secret-file && cli secret options are passed" do
    before do
      Chef::Config.reset
      bootstrap.config[:encrypted_data_bag_secret_file] = "/tmp/encrypted_data_bag_secret"
      bootstrap.config[:encrypted_data_bag_secret] = "data_bag_secret_key_passed_under_cli_secret_option"
    end
    it "gives preference to secret key passed under cli's secret-file option" do
      allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
        bootstrap.config[:encrypted_data_bag_secret_file]).
        and_return("data_bag_secret_key_passed_under_cli_secret_file_option")
      expect(bootstrap.load_correct_secret).to eq(
        "data_bag_secret_key_passed_under_cli_secret_file_option")
    end
  end

  context "knife secret-file, knife secret, cli secret-file && cli secret options are passed" do
    before do
      Chef::Config.reset
      Chef::Config[:knife][:encrypted_data_bag_secret_file] = "/tmp/knife_encrypted_data_bag_secret"
      Chef::Config[:knife][:encrypted_data_bag_secret] = "data_bag_secret_key_passed_under_knife_secret_option"
      bootstrap.config[:encrypted_data_bag_secret_file] = "/tmp/cli_encrypted_data_bag_secret"
      bootstrap.config[:encrypted_data_bag_secret] = "data_bag_secret_key_passed_under_cli_secret_option"
    end
    it "gives preference to secret key passed under cli's secret-file option" do
      allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
        Chef::Config[:knife][:encrypted_data_bag_secret_file]).
        and_return("data_bag_secret_key_passed_under_knife_secret_file_option")
      allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
        bootstrap.config[:encrypted_data_bag_secret_file]).
        and_return("data_bag_secret_key_passed_under_cli_secret_file_option")
      expect(bootstrap.load_correct_secret).to eq(
        "data_bag_secret_key_passed_under_cli_secret_file_option")
    end
  end

  context "knife secret-file && cli secret options are passed" do
    before do
      Chef::Config.reset
      Chef::Config[:knife][:encrypted_data_bag_secret_file] = "/tmp/encrypted_data_bag_secret"
      bootstrap.config[:encrypted_data_bag_secret] = "data_bag_secret_key_passed_under_cli_secret_option"
    end
    it "gives preference to secret key passed under cli's secret option" do
      allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
        Chef::Config[:knife][:encrypted_data_bag_secret_file]).
        and_return("data_bag_secret_key_passed_under_knife_secret_file_option")
      expect(bootstrap.load_correct_secret).to eq(
        "data_bag_secret_key_passed_under_cli_secret_option")
    end
  end

  context "knife secret && cli secret-file options are passed" do
    before do
      Chef::Config.reset
      Chef::Config[:knife][:encrypted_data_bag_secret] = "data_bag_secret_key_passed_under_knife_secret_option"
      bootstrap.config[:encrypted_data_bag_secret_file] = "/tmp/encrypted_data_bag_secret"
    end
    it "gives preference to secret key passed under cli's secret-file option" do
      allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
        bootstrap.config[:encrypted_data_bag_secret_file]).
        and_return("data_bag_secret_key_passed_under_cli_secret_file_option")
      expect(bootstrap.load_correct_secret).to eq(
        "data_bag_secret_key_passed_under_cli_secret_file_option")
    end
  end

  context "cli secret-file option is passed" do
    before do
      Chef::Config.reset
      bootstrap.config[:encrypted_data_bag_secret_file] = "/tmp/encrypted_data_bag_secret"
    end
    it "takes the secret key passed under cli's secret-file option" do
      allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(
        bootstrap.config[:encrypted_data_bag_secret_file]).
        and_return("data_bag_secret_key_passed_under_cli_secret_file_option")
      expect(bootstrap.load_correct_secret).to eq(
        "data_bag_secret_key_passed_under_cli_secret_file_option")
    end
  end

  it 'should pass exit code from failed winrm call' do
    allow(session).to receive(:exit_code).and_return(500)
    allow(bootstrap).to receive(:wait_for_remote_response)
    allow(bootstrap).to receive(:create_bootstrap_bat_command)
    allow(session).to receive(:relay_command).and_return(arch_session_result)
    allow(bootstrap.ui).to receive(:info)
    expect {
      bootstrap.run_with_pretty_exceptions
    }.to raise_error(SystemExit) { |e|
      expect(e.status).to eq(500)
    }
  end

  it 'should retry if a 401 is received from WinRM' do
    call_result_sequence = Array.new(initial_fail_count) {lambda {raise WinRM::WinRMHTTPTransportError.new('', '401')}}
    call_result_sequence.push(0)
    allow(bootstrap).to receive(:run_command).and_return(*call_result_sequence)
    allow(bootstrap).to receive(:print)
    allow(bootstrap.ui).to receive(:info)

    expect(bootstrap).to receive(:run_command).exactly(call_result_sequence.length).times
    bootstrap.send(:wait_for_remote_response, 2)
  end

  it 'should retry if something other than a 401 is received from WinRM' do
    call_result_sequence = Array.new(initial_fail_count) {lambda {raise WinRM::WinRMHTTPTransportError.new('', '500')}}
    call_result_sequence.push(0)
    allow(bootstrap).to receive(:run_command).and_return(*call_result_sequence)
    allow(bootstrap).to receive(:print)
    allow(bootstrap.ui).to receive(:info)

    expect(bootstrap).to receive(:run_command).exactly(call_result_sequence.length).times
    bootstrap.send(:wait_for_remote_response, 2)
  end

  it 'should keep retrying at 10s intervals if the timeout in minutes has not elapsed' do
    call_result_sequence = Array.new(initial_fail_count) {lambda {raise WinRM::WinRMHTTPTransportError.new('', '500')}}
    call_result_sequence.push(0)
    allow(bootstrap).to receive(:run_command).and_return(*call_result_sequence)
    allow(bootstrap).to receive(:print)
    allow(bootstrap.ui).to receive(:info)

    expect(bootstrap).to receive(:run_command).exactly(call_result_sequence.length).times
    bootstrap.send(:wait_for_remote_response, 2)
  end

  it 'should have a wait timeout of 2 minutes by default' do
    allow(bootstrap).to receive(:run_command).and_raise(WinRM::WinRMHTTPTransportError.new('','500'))
    allow(bootstrap).to receive(:create_bootstrap_bat_command).and_raise(SystemExit)
    expect(bootstrap).to receive(:wait_for_remote_response).with(2)

    allow(bootstrap.ui).to receive(:info)
    bootstrap.config[:auth_timeout] = bootstrap.options[:auth_timeout][:default]
    expect { bootstrap.bootstrap }.to raise_error(SystemExit)
  end

  it 'should not a wait for timeout on Errno::ECONNREFUSED' do
    allow(bootstrap).to receive(:run_command).and_raise(Errno::ECONNREFUSED.new)
    allow(bootstrap.ui).to receive(:info)
    bootstrap.config[:auth_timeout] = bootstrap.options[:auth_timeout][:default]
    expect(bootstrap.ui).to receive(:error).with("Connection refused connecting to localhost:5985.")

    # wait_for_remote_response is protected method, So define singleton test method to call it.
    bootstrap.define_singleton_method(:test_wait_for_remote_response){wait_for_remote_response(bootstrap.options[:auth_timeout][:default])}
    expect { bootstrap.test_wait_for_remote_response }.to raise_error(Errno::ECONNREFUSED)
  end

  it 'should stop retrying if more than 2 minutes has elapsed' do
    times = [ Time.new(2014, 4, 1, 22, 25), Time.new(2014, 4, 1, 22, 51), Time.new(2014, 4, 1, 22, 28) ]
    allow(Time).to receive(:now).and_return(*times)
    run_command_result = lambda {raise WinRM::WinRMHTTPTransportError, '401'}
    allow(bootstrap).to receive(:run_command).and_return(run_command_result)
    allow(bootstrap).to receive(:print)
    allow(bootstrap.ui).to receive(:info)
    allow(bootstrap.ui).to receive(:error)
    expect(bootstrap).to receive(:run_command).exactly(1).times
    bootstrap.config[:auth_timeout] = bootstrap.options[:auth_timeout][:default]
    expect { bootstrap.bootstrap }.to raise_error /Command execution failed./
  end

  it 'successfully bootstraps' do
    Chef::Config[:knife][:bootstrap_architecture] = :i386
    allow(bootstrap).to receive(:wait_for_remote_response)
    allow(bootstrap).to receive(:create_bootstrap_bat_command)
    allow(bootstrap).to receive(:run_command).and_return(0)
    expect(bootstrap.bootstrap).to eq(0)
    expect(Chef::Config[:knife][:architecture]).to eq(:i686)
  end

  context "when the target node is 64 bit" do
    it 'successfully bootstraps' do
      Chef::Config[:knife][:bootstrap_architecture] = :x86_64
      allow(bootstrap).to receive(:wait_for_remote_response)
      allow(bootstrap).to receive(:create_bootstrap_bat_command)
      allow(bootstrap).to receive(:run_command).and_return(0)
      expect(bootstrap.bootstrap).to eq(0)
      expect(Chef::Config[:knife][:architecture]).to eq(:x86_64)
    end
  end

  context 'FQDN validation -' do
    it 'should raise an error if FQDN value is not passed' do
      bootstrap.instance_variable_set(:@name_args, [])
      allow(bootstrap.ui).to receive(:error)
      expect {
      bootstrap.run
      }.to raise_error(SystemExit)
    end

    it 'should not raise error if FQDN value is passed' do
      bootstrap.instance_variable_set(:@name_args, ["fqdn_name"])
      expect {
      bootstrap.run
      }.not_to raise_error(SystemExit)
    end
  end

  context "when validation_key is not present" do
    before do
      allow(File).to receive(:exist?).with(File.expand_path(Chef::Config[:validation_key])).and_return(false)
      bootstrap.client_builder = instance_double("Chef::Knife::Bootstrap::ClientBuilder", :run => nil, :client_path => nil)
      Chef::Config[:knife] = {:chef_node_name => 'foo.example.com'}
    end

    it 'raises an exception if winrm_authentication_protocol is basic and transport is plaintext' do
      Chef::Config[:knife] = {:winrm_authentication_protocol => 'basic', :winrm_transport => 'plaintext', :chef_node_name => 'foo.example.com'}
      expect(bootstrap.ui).to receive(:error)
      expect { bootstrap.run }.to raise_error(SystemExit)
    end

    it 'raises an exception if chef_node_name is not present ' do
      Chef::Config[:knife] = {:chef_node_name => nil}
      expect(bootstrap.client_builder).not_to receive(:run)
      expect(bootstrap.client_builder).not_to receive(:client_path)
      expect(bootstrap.ui).to receive(:error)
      expect { bootstrap.bootstrap }.to raise_error(SystemExit)
    end
  end

  context "when doing chef vault" do
    let(:vault_handler) { double('vault_handler', :doing_chef_vault? => true) }
    let(:node_name) { 'foo.example.com' }
    before do
      allow(bootstrap).to receive(:wait_for_remote_response)
      allow(bootstrap).to receive(:create_bootstrap_bat_command)
      allow(bootstrap).to receive(:run_command).and_return(0)
      bootstrap.config[:chef_node_name] = node_name
      bootstrap.chef_vault_handler = vault_handler
    end

    context "builder does not respond to client" do
      before do
        bootstrap.client_builder = instance_double("Chef::Knife::Bootstrap::ClientBuilder", :run => nil, :client_path => nil)
      end

      it "passes a node search query to the handler" do
        expect(vault_handler).to receive(:run).with(node_name: node_name)
        bootstrap.bootstrap
      end
    end

    context "builder responds to client" do
      let(:client) { Chef::ApiClient.new }

      before do
        bootstrap.client_builder = double("Chef::Knife::Bootstrap::ClientBuilder", :run => nil, :client_path => nil, :client => client)
      end

      it "passes a node search query to the handler" do
        expect(vault_handler).to receive(:run).with(client)
        bootstrap.bootstrap
      end
    end
  end

  describe 'first_boot_attributes' do
    let(:first_boot_attributes) { { 'a1' => 'b1', 'a2' => 'b2', 'source' => 'hash' } }
    let(:json_file) { 'my_json.json' }
    let(:first_boot_attributes_from_file) { read_json_file(json_file) }

    before do
      File.open(json_file,"w+") do |f|
        f.write <<-EOH
{"b2" : "a3", "a4" : "b5", "source" : "file"}
        EOH
      end
    end

    context 'when none of the json-attributes options are passed' do
      it 'returns an empty hash' do
        response = bootstrap.first_boot_attributes
        expect(response).to be == {}
      end
    end

    context 'when only --json-attributes option is passed' do
      before do
        bootstrap.config[:first_boot_attributes] = first_boot_attributes
      end

      it 'returns the hash passed by the user in --json-attributes option' do
        response = bootstrap.first_boot_attributes
        expect(response).to be == first_boot_attributes
      end
    end

    context 'when only --json-attribute-file option is passed' do
      before do
        bootstrap.config[:first_boot_attributes_from_file] = first_boot_attributes_from_file
      end

      it 'returns the hash passed by the user in --json-attribute-file option' do
        response = bootstrap.first_boot_attributes
        expect(response).to be == { 'b2' => 'a3', 'a4' => 'b5', 'source' => 'file' }
      end
    end

    context 'when both the --json-attributes option and --json-attribute-file options are passed' do
      before do
        bootstrap.config[:first_boot_attributes] = first_boot_attributes
        bootstrap.config[:first_boot_attributes_from_file] = first_boot_attributes_from_file
      end

      it 'returns the hash passed by the user in --json-attributes option' do
        response = bootstrap.first_boot_attributes
        expect(response).to be == first_boot_attributes
      end
    end

    after do
      FileUtils.rm_rf json_file
    end
  end

  describe 'render_template' do
    before do
      allow(bootstrap).to receive(:first_boot_attributes).and_return(
        { 'a1' => 'b3', 'a2' => 'b1' }
      )
      allow(bootstrap).to receive(:load_correct_secret).and_return(
        'my_secret'
      )
      allow(Erubis::Eruby).to receive_message_chain(:new, :evaluate).and_return(
        'my_template'
      )
    end

    it 'sets correct values into config and returns the correct response' do
      response = bootstrap.render_template
      expect(bootstrap.config[:first_boot_attributes]).to be == { 'a1' => 'b3', 'a2' => 'b1' }
      expect(bootstrap.config[:secret]).to be == 'my_secret'
      expect(response).to be == 'my_template'
    end
  end
end

def read_json_file(file)
  Chef::JSONCompat.parse(File.read(file))
end
