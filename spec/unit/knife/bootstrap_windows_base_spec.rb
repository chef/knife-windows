#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Chirag Jog
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
require 'chef/knife/bootstrap_windows_base'

describe Chef::Knife::TemplateFinder do
  it "has the get_template as an instance method." do
    expect(Chef::Knife::TemplateFinder.instance_methods.include? :get_template).to eq true
  end
  it "any class that includes TemplateFinder module has get_template as its instance method." do
    class DummyClass
     include Chef::Knife::TemplateFinder
    end
    expect(DummyClass.new.methods.include? :get_template).to eq true
  end
end

describe Chef::Knife::BootstrapWindowsBase do
  it "includes the get_template as an instance method." do
    expect(Chef::Knife::BootstrapWindowsBase.instance_methods.include? :get_template).to eq true
  end
  it "any class that includes BootstrapWindowsBase module has get_template as its instance method." do
    Chef::Knife::BootstrapWindowsBase.stub(:included).and_return(true)
    class AnotherDummyClass
      include Chef::Knife::BootstrapWindowsBase
    end
    expect(AnotherDummyClass.new.methods.include? :get_template).to eq true
  end
end
