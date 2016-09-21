#
# Author:: Steven Murawski (<smurawski@chef.io)
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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
require 'chef/encrypted_data_bag_item'
require 'kconv'

class Chef
  class Knife
    module WinrmSharedOptions

      # Shared command line options for knife winrm and knife wsman test
      def self.included(includer)
        includer.class_eval do
          option :manual,
            :short => "-m",
            :long => "--manual-list",
            :boolean => true,
            :description => "QUERY is a space separated list of servers",
            :default => false

          option :winrm_attribute,
            :short => "-g ATTR",
            :long => "--winrm-attribute ATTR",
            :description => "The attribute to use for opening the connection - default is fqdn",
            :default => "fqdn"
        end
      end

    end
  end
end
