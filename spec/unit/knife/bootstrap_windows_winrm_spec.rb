#
# Author:: Adam Edwards(<adamed@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

Chef::Knife::Winrm.load_deps

describe Chef::Knife::BootstrapWindowsWinrm do
  before(:all) do
    Chef::Config.reset
  end

  before do
    #    Kernel.stub(:sleep).and_return 10
    allow(bootstrap).to receive(:sleep).and_return(10)
    allow(File).to receive(:exist?).with(File.expand_path(Chef::Config[:validation_key])).and_return(true)
  end

  after do
    #    Kernel.unstub(:sleep)
    allow(bootstrap).to receive(:sleep).and_return(10)
  end

  let(:bootstrap) { Chef::Knife::BootstrapWindowsWinrm.new(['winrm', '-d', 'windows-chef-client-msi',  '-x', 'Administrator', 'localhost']) }
  let(:session) { Chef::Knife::Winrm::WinrmSession.new({ :host => 'winrm.cloudapp.net', :port => '5986', :transport => :ssl }) }

  let(:initial_fail_count) { 4 }

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
    allow(bootstrap).to receive(:validate_name_args!).and_return(nil)
    allow(bootstrap.ui).to receive(:info)
    bootstrap.config[:auth_timeout] = bootstrap.options[:auth_timeout][:default]
    expect { bootstrap.bootstrap }.to raise_error(SystemExit)
  end

  it "should exit bootstrap with non-zero status if the bootstrap fails" do
    command_status = 1

    #Stub out calls to create the session and just get the exit codes back
    winrm_mock = Chef::Knife::Winrm.new
    allow(Chef::Knife::Winrm).to receive(:new).and_return(winrm_mock)
    allow(winrm_mock).to receive(:run).and_raise(SystemExit.new(command_status))
    #Skip over templating stuff and checking with the remote end
    allow(bootstrap).to receive(:create_bootstrap_bat_command)
    allow(bootstrap).to receive(:wait_for_remote_response)
    allow(bootstrap.ui).to receive(:info)

    expect { bootstrap.run_with_pretty_exceptions }.to raise_error(SystemExit) { |e| expect(e.status).to eq(command_status) }
  end

  it 'should stop retrying if more than 2 minutes has elapsed' do
    times = [ Time.new(2014, 4, 1, 22, 25), Time.new(2014, 4, 1, 22, 51), Time.new(2014, 4, 1, 22, 28) ]
    allow(Time).to receive(:now).and_return(*times)
    run_command_result = lambda {raise WinRM::WinRMHTTPTransportError, '401'}
    allow(bootstrap).to receive(:validate_name_args!).and_return(nil)
    allow(bootstrap).to receive(:run_command).and_return(run_command_result)
    allow(bootstrap).to receive(:print)
    allow(bootstrap.ui).to receive(:info)
    allow(bootstrap.ui).to receive(:error)
    expect(bootstrap).to receive(:run_command).exactly(1).times
    bootstrap.config[:auth_timeout] = bootstrap.options[:auth_timeout][:default]
    expect { bootstrap.bootstrap }.to raise_error RuntimeError
  end

  context "when validation_key is not present" do
    if chef_12?
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

    if chef_11?
      before do
        allow(File).to receive(:exist?).with(File.expand_path(Chef::Config[:validation_key])).and_return(false)
      end

      it 'raises an exception if validation_key is not present in chef 11' do
        expect(bootstrap.ui).to receive(:error)
        expect { bootstrap.bootstrap }.to raise_error(SystemExit)
      end
    end
  end
end