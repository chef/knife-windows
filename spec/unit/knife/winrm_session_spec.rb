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
  let(:winrm_service) { double('WinRMWebService') }
  let(:options) { { transport: :plaintext } }

  before do
    @original_config = Chef::Config.hash_dup
    allow(WinRM::WinRMWebService).to receive(:new).and_return(winrm_service)
    allow(winrm_service).to receive(:set_timeout)
  end

  after do
    Chef::Config.configuration = @original_config
  end

  subject { Chef::Knife::WinrmSession.new(options) }

  describe "#initialize" do
    context "when a proxy is configured" do
      let(:proxy_uri) { 'blah.com' }

      before do
        Chef::Config[:http_proxy] = proxy_uri
      end

      it "sets the http_proxy to the configured proxy" do
        subject
        expect(ENV['HTTP_PROXY']).to eq("http://#{proxy_uri}")
      end
    end
  end

  describe "#relay_command" do
    it "run command and display commands output" do
      expect(winrm_service).to receive(:open_shell).ordered
      expect(winrm_service).to receive(:run_command).ordered
      expect(winrm_service).to receive(:get_command_output).ordered.and_return({})
      expect(winrm_service).to receive(:cleanup_command).ordered
      expect(winrm_service).to receive(:close_shell).ordered
      subject.relay_command("cmd.exe echo 'hi'")
    end
  end
end