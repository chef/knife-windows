#
# Author:: Steven Murawski <smurawski@chef.io>
# Copyright:: Copyright (c) 2015 Opscode, Inc.
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


describe Chef::Knife::WinrmSession do
  describe "#relay_command" do
    before do
      @service_mock = Object.new
      @service_mock.define_singleton_method(:open_shell){}
      @service_mock.define_singleton_method(:run_command){}
      @service_mock.define_singleton_method(:cleanup_command){}
      @service_mock.define_singleton_method(:get_command_output){|t,y| {}}
      @service_mock.define_singleton_method(:close_shell){}
      allow(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(:transport => :plaintext)).and_call_original
      allow(WinRM::WinRMWebService).to receive(:new).and_return(@service_mock)
      @session = Chef::Knife::WinrmSession.new({transport: :plaintext})
    end

    it "run command and display commands output" do
      expect(@service_mock).to receive(:open_shell).ordered
      expect(@service_mock).to receive(:run_command).ordered
      expect(@service_mock).to receive(:get_command_output).ordered.and_return({})
      expect(@service_mock).to receive(:cleanup_command).ordered
      expect(@service_mock).to receive(:close_shell).ordered
      @session.relay_command("cmd.exe echo 'hi'")
    end
  end
end