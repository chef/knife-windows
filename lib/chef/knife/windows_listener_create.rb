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
    class WindowsListenerCreate < Knife

      banner "knife windows listener create (options)"

      option :cert_install,
        :short => "-c CERT_PATH",
        :long => "--cert-install CERT_PATH",
        :description => "Adds specified certificate to the Windows Certificate Store's Local Machine personal store before creating listener."

      option :port,
        :short => "-p PORT",
        :long => "--port PORT",
        :description => "Specify port. Default is 5986",
        :default => "5986"

      option :hostname,
        :short => "-h HOSTNAME",
        :long => "--hostname HOSTNAME",
        :description => "Hostname on the listener. Default is blank",
        :default => ""

      option :cert_thumbprint,
        :short => "-t THUMBPRINT",
        :long => "--cert-thumbprint THUMBPRINT",
        :description => "Thumbprint of the certificate. Required only if --cert-install option is not used."

      option :cert_passphrase,
        :short => "-cp PASSWORD",
        :long => "--cert-passphrase PASSWORD",
        :description => "Password for certificate."

      def get_cert_passphrase
        print "Enter given certificate's passphrase (empty for no passphrase):"
        passphrase = STDIN.gets
        passphrase.strip
      end

      def run
        STDOUT.sync = STDERR.sync = true

        if Chef::Platform.windows?
          begin
            if config[:cert_install]
              config[:cert_passphrase] = get_cert_passphrase unless config[:cert_passphrase]
              result = %x{powershell.exe -Command " '#{config[:cert_passphrase]}' | certutil  -importPFX '#{config[:cert_install]}' AT_KEYEXCHANGE"}
              if $?.exitstatus
                ui.info "Certificate installed to Certificate Store"
                result = %x{powershell.exe -Command " echo (Get-PfxCertificate #{config[:cert_install]}).thumbprint "}
                ui.info "Certificate Thumbprint: #{result}"
                config[:cert_thumbprint] = result.strip
              else
                ui.error "Error installing certificate to Certificate Store"
                ui.error result
                exit 1
              end
            end

            unless config[:cert_thumbprint]
              ui.error "Please specify the --cert-thumbprint"
              exit 1
            end

            result = %x{winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="#{config[:hostname]}";CertificateThumbprint="#{config[:cert_thumbprint]}";Port="#{config[:port]}"}}
            Chef::Log.debug result

            if ($?.exitstatus == 0)
              ui.info "WinRM listener created with Port: #{config[:port]} and CertificateThumbprint: #{config[:cert_thumbprint]}"
            else
              ui.error "Error creating WinRM listener. use -VV for more details."
            end

          rescue => e
            puts "ERROR: + #{e}"
          end
        else
          ui.error "WinRM listener can be created on Windows system only"
        end
      end

    end
  end
end
