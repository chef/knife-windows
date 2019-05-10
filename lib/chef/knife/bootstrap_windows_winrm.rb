#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2011-2016 Chef Software, Inc.
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

require 'chef/knife/bootstrap_windows_base'
require 'chef/knife/winrm'
require 'chef/knife/winrm_base'
require 'chef/knife/winrm_knife_base'


class Chef
  class Knife
    class BootstrapWindowsWinrm < Bootstrap

      include Chef::Knife::BootstrapWindowsBase
      include Chef::Knife::WinrmBase
      include Chef::Knife::WinrmCommandSharedFunctions

      deps do
        require 'chef/json_compat'
        require 'tempfile'
        Chef::Knife::Winrm.load_deps
        Chef::Knife::Bootstrap.load_deps
      end

      banner 'knife bootstrap windows winrm FQDN (options)'

      def run
         Chef::Application.fatal!(<<~EOM
         *knife windows bootstrap winrm*
          Core Chef now supports bootstrapping Windows systems without a knife plugin
          
          Use 'knife bootstrap -o winrm' instead.
          
          For more detail https://github.com/chef/chef/blob/master/RELEASE_NOTES.md#knife-bootstrap
          EOM
          )
      end

    end
  end
end
