
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright (c) 2012-2017 Chef Software, Inc.
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

def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

require_relative '../lib/chef/knife/core/windows_bootstrap_context'
require_relative '../lib/chef/knife/bootstrap_windows_winrm'
require_relative '../lib/chef/knife/bootstrap_windows_ssh'
require_relative '../lib/chef/knife/wsman_test'

if windows?
  require 'ruby-wmi'
end

def windows2012?
  is_win2k12 = false

  if  windows?
    this_operating_system = WMI::Win32_OperatingSystem.find(:first)
    os_version = this_operating_system.send('Version')

    # The operating system version is a string in the following form
    # that can be split into components based on the '.' delimiter:
    # MajorVersionNumber.MinorVersionNumber.BuildNumber
    os_version_components = os_version.split('.')

    if os_version_components.length < 2
      raise 'WMI returned a Windows version from Win32_OperatingSystem.Version ' +
        'with an unexpected format. The Windows version could not be determined.'
    end

    # Windows 6.2 is Windows Server 2012, so test the major and
    # minor version components
    is_win2k12 = os_version_components[0] == '6' && os_version_components[1] == '2'
  end

  is_win2k12
end

def windows2016?
  is_win2k16 = false

  if  windows?
    this_operating_system = WMI::Win32_OperatingSystem.find(:first)
    os_version = this_operating_system.send('Version')

    # The operating system version is a string in the following form
    # that can be split into components based on the '.' delimiter:
    # MajorVersionNumber.MinorVersionNumber.BuildNumber
    os_version_components = os_version.split('.')

    if os_version_components.length < 2
      raise 'WMI returned a Windows version from Win32_OperatingSystem.Version ' +
        'with an unexpected format. The Windows version could not be determined.'
    end

    # Windows 10.0 is Windows Server 2016, so test the major and
    # minor version components
    is_win2k16 = os_version_components[0] == '10' && os_version_components[1] == '0'
  end

  is_win2k16
end

def chef_gte_13?
  Gem::Version.new(Chef::VERSION) >= Gem::Version.new('13')
end

def chef_lt_14?
  Gem::Version.new(Chef::VERSION) < Gem::Version.new('14')
end

def chef_gte_14?
  Gem::Version.new(Chef::VERSION) >= Gem::Version.new('14')
end

def sample_data(file_name)
  file =  File.expand_path(File.dirname("spec/assets/*"))+"/#{file_name}"
  File.read(file)
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus => true
  config.filter_run_excluding :windows_only => true unless windows?
  config.filter_run_excluding :windows_2012_only => true unless windows2012?
  config.filter_run_excluding :chef_gte_13_only => true unless chef_gte_13?
  config.filter_run_excluding :chef_lt_14_only => true unless chef_lt_14?
  config.filter_run_excluding :chef_gte_14_only => true unless chef_gte_14?
end
