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
    class WindowsCertInstall < Knife

      banner "knife windows cert install CERT [CERT] (options)"

      option :winrm_cert_path,
        :short => "-c CERT_PATH",
        :long => "--winrm-cert-path CERT_PATH",
        :description => "Path of the certificate"

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
        if config[:winrm_cert_path].nil? && @name_args.empty?
          ui.error "Please specify the certificate path using --winrm-cert-path option!"
          exit 1
        end
        config[:winrm_cert_path] ||= @name_args.first if @name_args     
        file_path = config[:winrm_cert_path]
        config[:cert_passphrase] = get_cert_passphrase unless config[:cert_passphrase]

        begin
          ui.info "Adding certificate to the Certificate Store..."
          result = %x{powershell.exe -Command " '#{config[:cert_passphrase]}' | certutil -importPFX '#{config[:winrm_cert_path]}' AT_KEYEXCHANGE"}
          if $?.exitstatus == 0
            ui.info "Certificate added to Certificate Store"
          else
            ui.info "Error adding the certificate. Use -VV option for details"
          end
          Chef::Log.debug "#{result}"
        rescue => e
          puts "ERROR: + #{e}"
        end
      end
    end
  end
end
