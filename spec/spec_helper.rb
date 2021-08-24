
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

def sample_data(file_name)
  file = File.expand_path(File.dirname("spec/assets/*")) + "/#{file_name}"
  File.read(file)
end

class UnexpectedSystemExit < RuntimeError
  def self.from(system_exit)
    new(system_exit.message).tap { |e| e.set_backtrace(system_exit.backtrace) }
  end
end

RSpec.configure do |config|
  config.raise_on_warning = true
  config.raise_errors_for_deprecations!
  config.run_all_when_everything_filtered = true
  config.filter_run focus: true
  config.around(:example) do |ex|

    ex.run
  rescue SystemExit => e
    raise UnexpectedSystemExit.from(e)

  end
end
