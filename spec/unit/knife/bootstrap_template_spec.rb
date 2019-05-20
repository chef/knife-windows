#
# Author:: Chirag Jog (<chirag@clogeny.com>)
# Copyright:: Copyright (c) 2013 Chirag Jog
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


TEMPLATE_FILE = File.expand_path(File.dirname(__FILE__)) + "/../../../lib/chef/knife/bootstrap/windows-chef-client-msi.erb"

require 'spec_helper'

describe Chef::Knife::BootstrapWindowsWinrm do
  let(:template_file) { TEMPLATE_FILE }
  let(:options) { [] }
  let(:rendered_template) do
    knife.instance_variable_set("@template_file", template_file)
    knife.parse_options(options)
    # Avoid referencing a validation keyfile we won't find during #render_template
    template = IO.read(template_file).chomp
    knife.render_template(template)
  end
  subject(:knife) { described_class.new }

  before(:all) do
    @original_config = Chef::Config.hash_dup
    @original_knife_config = Chef::Config[:knife].dup
  end

  after(:all) do
    Chef::Config.configuration = @original_config
    Chef::Config[:knife] = @original_knife_config
  end

  before(:each) do
    Chef::Log.logger = Logger.new(StringIO.new)
    @knife = Chef::Knife::BootstrapWindowsWinrm.new
    # Merge default settings in.
    @knife.merge_configs
    @knife.config[:template_file] = template_file
    @stdout = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
    @stderr = StringIO.new
    allow(@knife.ui).to receive(:stderr).and_return(@stderr)
  end

  describe "specifying no_proxy with various entries" do
    let(:options){ ["--bootstrap-proxy", "", "--bootstrap-no-proxy", setting] }

    context "via --bootstrap-no-proxy" do
      let(:setting) { "api.chef.io" }

      it "renders the client.rb with a single FQDN no_proxy entry" do
        expect(rendered_template).to match(%r{.*no_proxy\s*\"api.chef.io\".*})
      end
    end
    context "via --bootstrap-no-proxy multiple" do
      let(:setting) { "api.chef.io,172.16.10.*" }

      it "renders the client.rb with comma-separated FQDN and wildcard IP address no_proxy entries" do
        expect(rendered_template).to match(%r{.*no_proxy\s*"api.chef.io,172.16.10.\*".*})
      end
    end
  end

  describe "specifying --msi-url" do
    context "with explicitly provided --msi-url" do
      let(:options) { ["--msi-url", "file:///something.msi"] }

      it "bootstrap batch file must fetch from provided url" do
        expect(rendered_template).to match(%r{.*REMOTE_SOURCE_MSI_URL=file:///something\.msi.*})
      end
    end
    context "with no provided --msi-url" do
      it "bootstrap batch file must fetch from provided url" do
        expect(rendered_template).to match(%r{.*REMOTE_SOURCE_MSI_URL=https://www\.chef\.io/.*})
      end
    end
  end

  describe "specifying knife_config[:architecture]" do
    it "puts the target architecture into the msi_url" do
      Chef::Config[:knife][:architecture] = :x86_64
      expect(rendered_template).to match(/MACHINE_ARCH=x86_64/)
    end
  end

  describe "when setting client_d_dir" do
    before do
      Chef::Config[:client_d_dir] = client_d_dir
    end

    context "client_d_dir is nil" do
      let(:client_d_dir) { nil }

      it "does not create c:/chef/client.d" do
        expect(rendered_template).not_to match(%r{mkdir c:\chef\client.d})
      end
    end

    context "client_d_dir is set" do
      let(:client_d_dir) do
        Chef::Util::PathHelper.cleanpath(
        File.join(File.dirname(__FILE__), "../../data/client.d_00")) end

      it "creates c:/chef/client.d" do
        expect(rendered_template).to match(/mkdir C:\\chef\\client.d/)
      end

      context "a flat directory structure" do

        it "creates a foo directory" do
          expect(rendered_template).to match(/C:\\chef\\client.d\\foo/)
        end

        it "creates a file 00-foo.rb" do
          expect(rendered_template).to match(/C:\\chef\\client.d\\00-foo.rb/)
          expect(rendered_template).to match("d6f9b976-289c-4149-baf7-81e6ffecf228")
        end

        it "creates a file bar" do
          expect(rendered_template).to match(/C:\\chef\\client.d\\foo\\bar.rb/)
          expect(rendered_template).to match("1 / 0")
        end
      end
    end
  end

end
