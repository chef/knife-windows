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

describe "While Windows Bootstrapping" do
  context "the default Windows bootstrapping template" do
    bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
    bootstrap.config[:template_file] = TEMPLATE_FILE

    template = bootstrap.load_template
    template_file_lines = template.split('\n')
    it "should download Platform specific MSI" do
      download_url=template_file_lines.find {|l| l.include?("url=")}
      download_url.include?("%MACHINE_OS%") && download_url.include?("%MACHINE_ARCH%")
    end
    it "should download specific version of MSI if supplied" do
      download_url_ext= template_file_lines.find {|l| l.include?("url +=")}
      download_url_ext.include?("[:bootstrap_version]")
    end
  end
end

describe Chef::Knife::BootstrapWindowsWinrm do
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
    @knife.config[:template_file] = TEMPLATE_FILE
    @stdout = StringIO.new
    @knife.ui.stub(:stdout).and_return(@stdout)
    @stderr = StringIO.new
    @knife.ui.stub(:stderr).and_return(@stderr)
  end

  describe "specifying no_proxy with various entries" do
    subject(:knife) { described_class.new }
    let(:options){ ["--bootstrap-proxy", "", "--bootstrap-no-proxy", setting] }
    let(:template_file) { TEMPLATE_FILE }
    let(:rendered_template) do
      knife.instance_variable_set("@template_file", template_file)
      knife.parse_options(options)
      # Avoid referencing a validation keyfile we won't find during #render_template
      template_string = knife.read_template.gsub(/^.*[Vv]alidation_key.*$/, '')
      knife.render_template(template_string)
    end

    context "via --bootstrap-no-proxy" do
      let(:setting) { "api.opscode.com" }

      it "renders the client.rb with a single FQDN no_proxy entry" do
        rendered_template.should match(%r{.*no_proxy\s*\"api.opscode.com\".*})
      end
    end
    context "via --bootstrap-no-proxy multiple" do
      let(:setting) { "api.opscode.com,172.16.10.*" }

      it "renders the client.rb with comma-separated FQDN and wildcard IP address no_proxy entries" do
        rendered_template.should match(%r{.*no_proxy\s*"api.opscode.com,172.16.10.\*".*})
      end
    end
  end
end
