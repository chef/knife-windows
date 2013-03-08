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

TEMPLATE_FILE = File.expand_path(File.dirname(__FILE__)) + "/lib/chef/knife/bootstrap/windows-chef-client-msi.erb"

require 'spec_helper'

describe "While Windows Bootstrapping" do
  context "the default Windows bootstrapping template" do
    bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
    template = bootstrap.load_template("#{TEMPLATE_FILE}")
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
