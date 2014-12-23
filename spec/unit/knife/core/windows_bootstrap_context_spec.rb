#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

describe Chef::Knife::Core::WindowsBootstrapContext do
  let(:mock_bootstrap_context) { Chef::Knife::Core::WindowsBootstrapContext.new({ }, nil, { :knife => {} }) }

  before do
     allow(Chef::Knife::Core::WindowsBootstrapContext).to receive(:new).and_return(mock_bootstrap_context)
   end

  describe "latest_current_windows_chef_version_query" do
    it "returns the major version of the current version of Chef" do
      stub_const("Chef::VERSION", '11.1.2')
      expect(mock_bootstrap_context.latest_current_windows_chef_version_query).to eq("&v=11")
    end

    it "does not add prerelease if the version of Chef installed is a prerelease" do
      stub_const("Chef::VERSION", '13.0.1.alpha.1')
      expect(mock_bootstrap_context.latest_current_windows_chef_version_query).not_to match(/&prerelease=true/)
    end

    it "does add prerelease if the version specified to be installed is a prerelease" do
      allow(mock_bootstrap_context).to receive(:knife_config).and_return(Mash.new(:bootstrap_version => "12.0.0.alpha.1"))
      expect(mock_bootstrap_context.latest_current_windows_chef_version_query).to eq("&v=12.0.0.alpha.1&prerelease=true")
    end

    context "when the prerelease config option is set" do
      before do
        mock_bootstrap_context.instance_variable_set(:@config, Mash.new(:prerelease => true))
      end

      it "sets prerelease to true in the returned string" do
        expect(mock_bootstrap_context.latest_current_windows_chef_version_query).to eq("&prerelease=true")
      end
    end
  end
end
