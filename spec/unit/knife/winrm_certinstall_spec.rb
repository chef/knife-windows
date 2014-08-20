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
require 'chef/knife/winrm_certinstall'

describe Chef::Knife::WinrmCertinstall do
  before(:all) do
    @certinstall = Chef::Knife::WinrmCertinstall.new
  end

  it "installs certificate" do
    @certinstall.config[:cert_path] = "test-path"
    @certinstall.config[:cert_passphrase] = "your-secret!"
    @certinstall.should_receive("exec").with("powershell.exe certutil -p 'your-secret!' -importPFX 'test-path' AT_KEYEXCHANGE")
    @certinstall.ui.should_receive(:info).with("Certificate installed to certificate store.")
    @certinstall.run
  end
end