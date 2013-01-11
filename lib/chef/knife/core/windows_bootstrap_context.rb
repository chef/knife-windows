#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/knife/core/bootstrap_context'

class Chef
  class Knife
    module Core
      # Instances of BootstrapContext are the context objects (i.e., +self+) for
      # bootstrap templates. For backwards compatability, they +must+ set the
      # following instance variables:
      # * @config   - a hash of knife's config values
      # * @run_list - the run list for the node to boostrap
      #
      class WindowsBootstrapContext < BootstrapContext

        def initialize(config, run_list, chef_config)
          @config       = config
          @run_list     = run_list
          @chef_config  = chef_config
          super(config, run_list, chef_config)
        end

        def validation_key
          escape_and_echo(super)
        end

        def encrypted_data_bag_secret
          escape_and_echo(@config[:encrypted_data_bag_secret])
        end

        def config_content
          client_rb = <<-CONFIG
log_level        :info
log_location     STDOUT

chef_server_url  "#{@chef_config[:chef_server_url]}"
validation_client_name "#{@chef_config[:validation_client_name]}"
client_key        "c:/chef/client.pem"
validation_key    "c:/chef/validation.pem"

file_cache_path   "c:/chef/cache"
file_backup_path  "c:/chef/backup"
cache_options     ({:path => "c:/chef/cache/checksums", :skip_expires => true})

CONFIG
          if @config[:chef_node_name]
            client_rb << %Q{node_name "#{@config[:chef_node_name]}"\n}
          else
            client_rb << "# Using default node name (fqdn)\n"
          end

          if knife_config[:bootstrap_proxy]
            client_rb << "\n"
            client_rb << %Q{http_proxy        "#{knife_config[:bootstrap_proxy]}"\n}
            client_rb << %Q{https_proxy       "#{knife_config[:bootstrap_proxy]}"\n}
          end

          if @config[:encrypted_data_bag_secret]
            client_rb << %Q{encrypted_data_bag_secret "c:/chef/encrypted_data_bag_secret"\n}
          end

          escape_and_echo(client_rb)
        end

        def start_chef
          start_chef = "SET \"PATH=%PATH%;C:\\ruby\\bin;C:\\opscode\\chef\\bin;C:\\opscode\\chef\\embedded\\bin\"\n"
          start_chef << "chef-client -c c:/chef/client.rb -j c:/chef/first-boot.json -E #{bootstrap_environment}\n"
        end

        def run_list
          escape_and_echo({ "run_list" => @run_list }.to_json)
        end

        def win_wget
          win_wget = <<-WGET
url = WScript.Arguments.Named("url")
path = WScript.Arguments.Named("path")
proxy = null
Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP")
Set wshShell = CreateObject( "WScript.Shell" )
Set objUserVariables = wshShell.Environment("USER")

'http proxy is optional
'attempt to read from HTTP_PROXY env var first
On Error Resume Next

If NOT (objUserVariables("HTTP_PROXY") = "") Then
proxy = objUserVariables("HTTP_PROXY")

'fall back to named arg
ElseIf NOT (WScript.Arguments.Named("proxy") = "") Then
proxy = WScript.Arguments.Named("proxy")
End If

If NOT isNull(proxy) Then
'setProxy method is only available on ServerXMLHTTP 6.0+
Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP.6.0")
objXMLHTTP.setProxy 2, proxy
End If

On Error Goto 0

objXMLHTTP.open "GET", url, false
objXMLHTTP.send()
If objXMLHTTP.Status = 200 Then
Set objADOStream = CreateObject("ADODB.Stream")
objADOStream.Open
objADOStream.Type = 1
objADOStream.Write objXMLHTTP.ResponseBody
objADOStream.Position = 0
Set objFSO = Createobject("Scripting.FileSystemObject")
If objFSO.Fileexists(path) Then objFSO.DeleteFile path
Set objFSO = Nothing
objADOStream.SaveToFile path
objADOStream.Close
Set objADOStream = Nothing
End if
Set objXMLHTTP = Nothing
WGET
          escape_and_echo(win_wget)
        end

        def win_wget_ps
          win_wget_ps = <<-WGET_PS
param(
   [String] $remoteUrl,
   [String] $localPath
)

$webClient = new-object System.Net.WebClient; 

$webClient.DownloadFile($remoteUrl, $localPath);
WGET_PS

          escape_and_echo(win_wget_ps)
        end

        def install_chef
          install_chef = 'msiexec /qb /i "%LOCAL_DESTINATION_MSI_PATH%"'
        end

        def bootstrap_directory
          bootstrap_directory = "C:\\chef"
        end

        def local_download_path
          local_download_path = "%TEMP%\\chef-client-latest.msi"
        end

        # escape WIN BATCH special chars
        # and prefixes each line with an
        # echo
        def escape_and_echo(file_contents)
          file_contents.gsub(/^(.*)$/, 'echo.\1').gsub(/([(<|>)^])/, '^\1')
        end
      end
    end
  end
end
