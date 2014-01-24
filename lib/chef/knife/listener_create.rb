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
require 'openssl'

class Chef
  class Knife
    class Listener < Knife

      banner "knife listener create (options)"

      option :cert_path,
        :short => "-c CERT_PATH",
        :long => "--cert-path CERT_PATH",
        :description => "Path of the certificate path. Default is './winrmcert.pfx'",
        :default => "./winrmcert.pfx"

      option :port,
        :short => "-p PORT",
        :long => "--port PORT",
        :description => "Specify port. Default is 5986",
        :default => "5986"

      def run
        STDOUT.sync = STDERR.sync = true
        file_path = config[:cert_path]

        begin
          exec "cmd.exec winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=\'#{hostname}\';CertificateThumbprint=\'#{thumbprint}\';Port=\'#{config[:port]}\'}"
          ui.info "Certificate installed to certificate store."
        rescue => e
          puts "ERROR: + #{e}"
        end
      end

    end
  end
end

