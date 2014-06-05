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
    @original_knife_config = Chef::Config[:knife].nil? ? nil : Chef::Config[:knife].dup
  end

  after(:all) do
    Chef::Config.configuration = @original_config
    Chef::Config[:knife] = @original_knife_config if @original_knife_config
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
    @node_bar.automatic_attrs[:ec2][:public_hostname] = "somewhere.com"
  end

  describe "#configure_session" do
    before do
      @query = double("Chef::Search::Query")
    end

    context "when there are some hosts found but they do not have an attribute to connect with" do
      before do
        @knife.config[:manual] = false
        @query.stub(:search).and_return([[@node_foo, @node_bar]])
        @node_foo.automatic_attrs[:fqdn] = nil
        @node_bar.automatic_attrs[:fqdn] = nil
        Chef::Search::Query.stub(:new).and_return(@query)
      end
    
      it "should raise a specific error (KNIFE-222)" do
        @knife.ui.should_receive(:fatal).with(/does not have the required attribute/)
        @knife.should_receive(:exit).with(10)
        @knife.configure_session
      end
    end

    context "when there are nested attributes" do
      before do
        @knife.config[:manual] = false
        @query.stub(:search).and_return([[@node_foo, @node_bar]])
        Chef::Search::Query.stub(:new).and_return(@query)
      end
    
      it "should use nested attributes (KNIFE-276)" do
        @knife.config[:attribute] = "ec2.public_hostname"
        @knife.stub(:session_from_list)
        @knife.configure_session

      end
    end

    describe Chef::Knife::Winrm do
      context "when executing the run command which sets the process exit code" do
        before(:each) do
          Chef::Config[:knife] = {:winrm_transport => :http}
          @winrm = Chef::Knife::Winrm.new(['-m', 'localhost', '-x', 'testuser', '-P', 'testpassword', 'echo helloworld'])
        end

        after(:each) do
          Chef::Config.configuration = @original_config
          Chef::Config[:knife] = @original_knife_config if @original_knife_config
        end

        it "should return with 0 if the command succeeds" do
          @winrm.stub(:winrm_command).and_return(0)
          exit_code = @winrm.run
          exit_code.should == 0
        end

        it "should exit the process with 0 if the command fails and returns config is not set" do
          @winrm.stub(:winrm_command).and_return(1)
          exit_code = @winrm.run
          exit_code.should == 0
        end

        it "should exit the process with non-zero status if the command fails and returns config is set to 0" do
          command_status = 1
          @winrm.config[:returns] = [0,53]
          Chef::Config[:knife][:returns] = [0,53]
          @winrm.stub(:winrm_command).and_return(command_status)
          EventMachine::WinRM::Session.any_instance.stub(:exit_codes).and_return({"thishost" => command_status})
          expect { @winrm.run_with_pretty_exceptions }.to raise_error(SystemExit) { |e| e.status.should == command_status }
        end

        it "should exit the process with a zero status if the command returns an expected non-zero status" do
          command_status = 53
          Chef::Config[:knife][:returns] = [0,53]
          @winrm.stub(:winrm_command).and_return(command_status)
          EventMachine::WinRM::Session.any_instance.stub(:exit_codes).and_return({"thishost" => command_status})
          exit_code = @winrm.run
          exit_code.should == 0
        end

        it "should exit the process with a zero status if the command returns an expected non-zero status" do
          command_status = 53
          Chef::Config[:knife][:returns] = [0,53]
          @winrm.stub(:winrm_command).and_return(command_status)
          EventMachine::WinRM::Session.any_instance.stub(:exit_codes).and_return({"thishost" => command_status})
          exit_code = @winrm.run
          exit_code.should == 0
        end

        it "should exit the process with 100 if command execution raises an exception other than 401" do
          @winrm.stub(:winrm_command).and_raise(WinRM::WinRMHTTPTransportError, '500')
          expect { @winrm.run_with_pretty_exceptions }.to raise_error(SystemExit) { |e| e.status.should == 100 }
        end

        it "should exit the process with 100 if command execution raises a 401" do
          @winrm.stub(:winrm_command).and_raise(WinRM::WinRMHTTPTransportError, '401')
          expect { @winrm.run_with_pretty_exceptions }.to raise_error(SystemExit) { |e| e.status.should == 100 }
        end

        it "should exit the process with 0 if command execution raises a 401 and suppress_auth_failure is set to true" do
          @winrm.config[:suppress_auth_failure] = true
          @winrm.stub(:winrm_command).and_raise(WinRM::WinRMHTTPTransportError, '401')
          exit_code = @winrm.run_with_pretty_exceptions
          exit_code.should == 401
        end

        describe "validate sspinegotiate transport option" do
          before do
            Chef::Config[:knife] = {:winrm_transport => :plaintext}
            @winrm.stub(:winrm_command).and_return(0)
          end

          it "should have winrm opts transport set to sspinegotiate for windows" do
            Chef::Platform.stub(:windows?).and_return(true)

            @winrm.session.should_receive(:use).with("localhost", {:user=>"testuser", :password=>"testpassword", :port=>nil, :operation_timeout=>1800, :basic_auth_only=>true, :transport=>:sspinegotiate, :disable_sspi=>false})
            exit_code = @winrm.run
          end

          it "should not have winrm opts transport set to sspinegotiate for unix" do
            Chef::Platform.stub(:windows?).and_return(false)

            @winrm.session.should_receive(:use).with("localhost", {:user=>"testuser", :password=>"testpassword", :port=>nil, :operation_timeout=>1800, :basic_auth_only=>true, :transport=>:plaintext, :disable_sspi=>true})
            exit_code = @winrm.run
          end
        end

      end
    end
  end
end  
