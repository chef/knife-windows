
# Author:: Adam Edwards (<adamed@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative '../lib/chef/knife/core/windows_bootstrap_context'

def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

def windows2012?

  is_win2k12 = false

  # Use PowerShell script on Windows Server 2012 to reliably detect
  # the OS version. Windows 6.2 is Windows Server 2012.
  if windows?
    `powershell -noprofile -noninteractive -command "if ( [environment]::osversion.Version.Major -eq 6 -and [environment]::osversion.Version.Minor -eq 2 ) { throw 'Win2k12'}" > NUL`
    is_win2k12= $?.exitstatus != 0
  end

  is_win2k12

end


RSpec.configure do |config|

  config.treat_symbols_as_metadata_keys_with_true_values = true
  
  config.filter_run_excluding :windows_only => true unless windows?
  config.filter_run_excluding :windows_2012_only => true unless windows2012?

end

