# Author:: Mukta Aphale (<mukta.aphale@clogeny.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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
require 'chef/knife/winrm_base'

class Chef
  class Knife
    class WinrmCertinstall < Knife

      banner "knife winrm certinstall (options)"

      option :cert_path,
        :short => "-c CERT_PATH",
        :long => "--cert-path CERT_PATH",
        :description => "Path of the certificate path. Default is './winrmcert.pfx'",
        :default => "./winrmcert.pfx"

      option :cert_passphrase,
        :short => "-cp PASSWORD",
        :long => "--cert-passphrase PASSWORD",
        :description => "Passphraseth of the certificate. Default is 'winrmcertgen'",
        :default => "winrmcertgen"

      def run
        STDOUT.sync = STDERR.sync = true
        file_path = config[:cert_path]

        begin
          puts %x{powershell.exe certutil -p "#{config[:cert_passphrase]}" -importPFX "#{config[:cert_path]}" AT_KEYEXCHANGE}
          ui.info "Certificate installed to certificate store."
        rescue => e
          puts "ERROR: + #{e}"
        end
      end
    end
  end
end

