#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2011-2020 Chef Software, Inc.
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

require "chef/knife"
require_relative "helpers/bootstrap_windows_base"

class Chef
  class Knife
    class BootstrapWindowsWinrm < Bootstrap

      include Chef::Knife::BootstrapWindowsBase

      banner "knife bootstrap windows winrm FQDN (options) DEPRECATED"

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
