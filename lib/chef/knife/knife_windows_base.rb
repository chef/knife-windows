#
# Author:: Aliasgar Batterywala (<aliasgar.batterywala@clogeny.com>)
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

class Chef
  class Knife
    module KnifeWindowsBase

      # E.G. for config value 'attribute', look for :attribute
      # and then :winrm_attribute,
      def locate_config_value(key)
        key    = key.to_s
        symbol = key.to_sym
        # look for config key as stated
        if not value = config[symbol] || Chef::Config[:knife][symbol] || default_config[symbol]
          if key =~ /^winrm_/
            # if stated key starts with winrm_, remove it and look for that
            symbol = key.gsub(/^winrm_/, '').to_sym
          else
            # look for key with 'winrm_' prepended
            symbol = "winrm_#{key}".to_sym
          end
          Chef::Log.debug("Couldn't find value for config key: \"#{key}\", trying \"#{symbol.to_s}\"")
          value = config[symbol] || Chef::Config[:knife][symbol] || default_config[symbol]
        end
        Chef::Log.debug("Config: #{symbol.to_s}: #{value ? value : ''}")
        value
      end
    end
  end
end

