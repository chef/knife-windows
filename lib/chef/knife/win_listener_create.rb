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
    class WinListenerCreate < Knife

      banner "knife win listener create (options)"

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

      option :hostname,
        :short => "-h HOSTNAME",
        :long => "--hostname HOSTNAME",
        :description => "Hostname on the listener. Default is *",
        :default => "*"
          
      option :thumbprint,
        :short => "-t THUMBPRINT",
        :long => "--thumbprint THUMBPRINT",
        :description => "Thumbprint of the certificate"

      option :basic_auth,
        :long => "--[no-]basic-auth",
        :description => "Disable basic authentication on the WinRM service.",
        :boolean => true,
        :default => true

      option :cert_passphrase,
        :short => "-cp PASSWORD",
        :long => "--cert-passphrase PASSWORD",
        :description => "Password for certificate."

      option :cert_install,
        :long => "--cert-install",
        :description => "Install certificate to store of the certificate.",
        :boolean => true,
        :default => false

      def get_cert_passphrase
        print "Enter given certificate's passphrase (empty for no passphrase):"
        passphrase = STDIN.gets
        passphrase.strip
      end

      def run
        STDOUT.sync = STDERR.sync = true
        file_path = config[:cert_path]

        begin
          if config[:cert_install]
            config[:cert_passphrase] = get_cert_passphrase unless config[:cert_passphrase]
            puts %x{powershell.exe certutil -p "#{config[:cert_passphrase]}" -importPFX "#{config[:cert_path]}" AT_KEYEXCHANGE}
            ui.info "Certificate installed to certificate store."
          end

          puts %x{winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="#{config[:hostname]}";CertificateThumbprint="#{config[:thumbprint]}";Port="#{config[:port]}"}}

          puts %x{winrm set winrm/config/service/auth @{Basic="#{config[:basic_auth]}"}} unless config[:basic_auth]

          ui.info "Winrm listener created"
        rescue => e
          puts "ERROR: + #{e}"
        end
      end
    end
  end
end
