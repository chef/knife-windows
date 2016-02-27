#
# Author:: Chirag Jog (<chirag@clogeny.com>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

require 'chef/knife'
require 'chef/knife/winrm'
require 'chef/knife/bootstrap_windows_ssh'
require 'chef/knife/bootstrap_windows_winrm'
require 'chef/knife/wsman_test'

class Chef
  class Knife
    class WindowsHelper < Knife

      banner "#{BootstrapWindowsWinrm.banner}\n" +
              "#{BootstrapWindowsSsh.banner}\n" +
              "#{Winrm.banner}\n" +
              "#{WsmanTest.banner}"
    end
  end
end

