#
# Author:: Mukta Aphale <mukta.aphale@clogeny.com>
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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
require 'chef/knife/listener_create'

describe Chef::Knife::ListenerCreate do
  before(:all) do
    @listener = Chef::Knife::ListenerCreate.new
  end

  it "creates winrm listener" do
    @listener.config[:cert_path] = "test-path"
    @listener.config[:hostname] = "host"
    @listener.config[:thumbprint] = "CERT-THUMBPRINT"
    @listener.config[:port] = "5986"
    @listener.should_receive("exec").with("cmd.exec winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname='host';CertificateThumbprint='CERT-THUMBPRINT';Port='5986'}")
    @listener.ui.should_receive(:info).with("Winrm listener created")
    @listener.run
  end
end