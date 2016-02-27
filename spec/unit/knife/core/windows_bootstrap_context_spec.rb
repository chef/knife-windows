#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

describe Chef::Knife::Core::WindowsBootstrapContext do
  let(:mock_bootstrap_context) { Chef::Knife::Core::WindowsBootstrapContext.new({ }, nil, { :knife => {} }) }

  before do
     allow(Chef::Knife::Core::WindowsBootstrapContext).to receive(:new).and_return(mock_bootstrap_context)
   end

  describe "fips" do
    before do
      Chef::Config[:fips] = fips_mode
    end

    after do
      Chef::Config.reset!
    end

    context "when fips is set" do
      let(:fips_mode) { true }

      it "sets fips mode in the client.rb" do
        expect(mock_bootstrap_context.config_content).to match(/fips true/)
      end
    end

    context "when fips is not set" do
      let(:fips_mode) { false }

      it "sets fips mode in the client.rb" do
        expect(mock_bootstrap_context.config_content).not_to match(/fips true/)
      end
    end
  end

  describe "validation_key", :chef_gte_12_only do
    before do
      mock_bootstrap_context.instance_variable_set(:@config, Mash.new(:validation_key => "C:\\chef\\key.pem"))
    end

    it "should return false if validation_key does not exist" do
      allow(::File).to receive(:expand_path)
      allow(::File).to receive(:exist?).and_return(false)
      expect(mock_bootstrap_context.validation_key).to eq(false)
    end
  end

  describe "latest_current_windows_chef_version_query" do
    it "returns the major version of the current version of Chef" do
      stub_const("Chef::VERSION", '11.1.2')
      expect(mock_bootstrap_context.latest_current_windows_chef_version_query).to eq("&v=11")
    end

    it "does not add prerelease if the version of Chef installed is a prerelease" do
      stub_const("Chef::VERSION", '42.0.1.alpha.1')
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

  describe "msi_url" do
    context "when config option is not set" do
      before do
        expect(mock_bootstrap_context).to receive(:latest_current_windows_chef_version_query).and_return("&v=something")
      end

      it "returns a chef.io msi url with minimal url parameters" do
        reference_url = "https://www.chef.io/chef/download?p=windows&v=something"
        expect(mock_bootstrap_context.msi_url).to eq(reference_url)
      end

      it "returns a chef.io msi url with provided url parameters substituted" do
        reference_url = "https://www.chef.io/chef/download?p=windows&pv=machine&m=arch&DownloadContext=ctx&v=something"
        expect(mock_bootstrap_context.msi_url('machine', 'arch', 'ctx')).to eq(reference_url)
      end
    end

    context "when msi_url config option is set" do
      let(:custom_url) { "file://something" }

      before do
        mock_bootstrap_context.instance_variable_set(:@config, Mash.new(:msi_url => custom_url))
      end

      it "returns the overriden url" do
        expect(mock_bootstrap_context.msi_url).to eq(custom_url)
      end

      it "doesn't introduce any unnecessary query parameters if provided by the template" do
        expect(mock_bootstrap_context.msi_url('machine', 'arch', 'ctx')).to eq(custom_url)
      end
    end
  end

  describe "bootstrap_install_command for bootstrap through WinRM" do
    context "when bootstrap_install_command option is passed on CLI" do
      let(:bootstrap) { Chef::Knife::BootstrapWindowsWinrm.new(['--bootstrap-install-command', 'chef-client']) }
      before do
        bootstrap.config[:bootstrap_install_command] = "chef-client"
      end

      it "sets the bootstrap_install_command option under Chef::Config::Knife object" do
        expect(Chef::Config[:knife][:bootstrap_install_command]).to eq("chef-client")
      end

      after do
        bootstrap.config.delete(:bootstrap_install_command)
        Chef::Config[:knife].delete(:bootstrap_install_command)
      end
    end

    context "when bootstrap_install_command option is not passed on CLI" do
      let(:bootstrap) { Chef::Knife::BootstrapWindowsWinrm.new([]) }
      it "does not set the bootstrap_install_command option under Chef::Config::Knife object" do
        expect(Chef::Config[:knife][:bootstrap_install_command]). to eq(nil)
      end
    end
  end

  describe "bootstrap_install_command for bootstrap through SSH" do
    context "when bootstrap_install_command option is passed on CLI" do
      let(:bootstrap) { Chef::Knife::BootstrapWindowsSsh.new(['--bootstrap-install-command', 'chef-client']) }
      before do
        bootstrap.config[:bootstrap_install_command] = "chef-client"
      end

      it "sets the bootstrap_install_command option under Chef::Config::Knife object" do
        expect(Chef::Config[:knife][:bootstrap_install_command]).to eq("chef-client")
      end

      after do
        bootstrap.config.delete(:bootstrap_install_command)
        Chef::Config[:knife].delete(:bootstrap_install_command)
      end
    end

    context "when bootstrap_install_command option is not passed on CLI" do
      let(:bootstrap) { Chef::Knife::BootstrapWindowsSsh.new([]) }
      it "does not set the bootstrap_install_command option under Chef::Config::Knife object" do
        expect(Chef::Config[:knife][:bootstrap_install_command]). to eq(nil)
      end
    end
  end

end
