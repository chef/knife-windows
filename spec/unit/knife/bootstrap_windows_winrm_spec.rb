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


describe Chef::Knife::BootstrapWindowsWinrm do
  before(:all) do
    Chef::Config.reset
  end

  before do
    #    Kernel.stub(:sleep).and_return 10
    bootstrap.stub(:sleep).and_return 10
  end

  after do
    #    Kernel.unstub(:sleep)
    bootstrap.stub(:sleep).and_return 10
  end

  let (:bootstrap) { Chef::Knife::BootstrapWindowsWinrm.new }
  let(:initial_fail_count) { 4 }  
  it 'should retry if a 401 is received from WinRM' do
    call_result_sequence = Array.new(initial_fail_count) {lambda {raise WinRM::WinRMHTTPTransportError, '401'}}
    call_result_sequence.push(0)
    bootstrap.stub(:run_command).and_return(*call_result_sequence)

    bootstrap.should_receive(:run_command).exactly(call_result_sequence.length).times
    bootstrap.send(:wait_for_remote_response, 2)
  end

  it 'should retry if something other than a 401 is received from WinRM' do
    call_result_sequence = Array.new(initial_fail_count) {lambda {raise WinRM::WinRMHTTPTransportError, '500'}}
    call_result_sequence.push(0)
    bootstrap.stub(:run_command).and_return(*call_result_sequence)

    bootstrap.should_receive(:run_command).exactly(call_result_sequence.length).times
    bootstrap.send(:wait_for_remote_response, 2)
  end

  it 'should have a wait timeout of 25 minutes by default' do
    bootstrap.stub(:run_command).and_raise WinRM::WinRMHTTPTransportError
    bootstrap.stub(:create_bootstrap_bat_command).and_raise SystemExit
    bootstrap.should_receive(:wait_for_remote_response).with(25)
    bootstrap.stub(:validate_name_args!).and_return(nil)
    bootstrap.config[:auth_timeout] = bootstrap.options[:auth_timeout][:default]
    expect { bootstrap.bootstrap }.to raise_error SystemExit
  end

  it 'should keep retrying at 10s intervals if the timeout in minutes has not elapsed' do
    call_result_sequence = Array.new(initial_fail_count) {lambda {raise WinRM::WinRMHTTPTransportError, '500'}}
    call_result_sequence.push(0)
    bootstrap.stub(:run_command).and_return(*call_result_sequence)

    bootstrap.should_receive(:run_command).exactly(call_result_sequence.length).times
    bootstrap.send(:wait_for_remote_response, 2)
  end

  it 'should stop retrying if more than 25 minutes has elapsed' do
    times = [ Time.new(2014, 4, 1, 22, 25), Time.new(2014, 4, 1, 22, 51), Time.new(2014, 4, 1, 22, 52) ]
    Time.stub(:now).and_return(*times)    
    run_command_result = lambda {raise WinRM::WinRMHTTPTransportError, '401'}
    bootstrap.stub(:validate_name_args!).and_return(nil)
    bootstrap.stub(:run_command).and_return(run_command_result)
    bootstrap.should_receive(:run_command).exactly(1).times
    bootstrap.config[:auth_timeout] = bootstrap.options[:auth_timeout][:default]    
    expect { bootstrap.bootstrap }.to raise_error RuntimeError
  end
end
