#
# Author:: Bryan McLellan <btm@opscode.com>
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

describe Chef::Knife::Winrm do
  before(:all) do
    @original_config = Chef::Config.hash_dup
    @original_knife_config = Chef::Config[:knife].dup
  end

  after(:all) do
    Chef::Config.configuration = @original_config
    Chef::Config[:knife] = @original_knife_config
  end

  before do
    @knife = Chef::Knife::Winrm.new
    @knife.config[:attribute] = "fqdn"
    @node_foo = Chef::Node.new
    @node_foo.automatic_attrs[:fqdn] = "foo.example.org"
    @node_foo.automatic_attrs[:ipaddress] = "10.0.0.1"
    @node_bar = Chef::Node.new
    @node_bar.automatic_attrs[:fqdn] = "bar.example.org"
    @node_bar.automatic_attrs[:ipaddress] = "10.0.0.2"
  end

  describe "#configure_session" do
    before do
      @query = mock("Chef::Search::Query")
    end

    context "when there are some hosts found but they do not have an attribute to connect with" do
      before do
        @query.stub!(:search).and_return([[@node_foo, @node_bar]])
        @node_foo.automatic_attrs[:fqdn] = nil
        @node_bar.automatic_attrs[:fqdn] = nil
        Chef::Search::Query.stub!(:new).and_return(@query)
      end
    
      it "should raise a specific error (KNIFE-222)" do
        @knife.ui.should_receive(:fatal).with(/does not have the required attribute/)
        @knife.should_receive(:exit).with(10)
        @knife.configure_session
      end
    end
  end
end  
