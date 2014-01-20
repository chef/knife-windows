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
require 'socket'

class Chef
  class Knife
    class Certgen < Knife

      deps do
        require 'readline'
        require 'chef/search/query'
        require 'em-winrm'
      end

      attr_accessor :thumbprint, :hostname

      banner "knife certgen (options)"

      option :domain,
        :short => "-d DOMAIN",
        :long => "--domain DOMAIN",
        :description => "By default there will be no domain name. If user wants to give the hostname as '*.mydomain.com' then he must specify the domain as: --domain 'mydomain.com'"

      option :output_file,
        :short => "-o PATH",
        :long => "--output-file PATH",
        :description => "By default 2 files will be generated in the current folder as winrmcert.pfx and winrmcert.pem. You can specify alternate file path using this option. Eg: --output-file /home/.winrm/server_cert.pfx. This will create 2 files in the specified path with name server_cert.pem and sever_cert.pfx.",
        :default => "winrmcert"

      option :key_length,
        :short => "-k LENGTH",
        :long => "--key-length LENGTH",
        :description => "Default is 2048",
        :default => "2048"

      option :cert_validity,
        :short => "-cv MONTHS",
        :long => "--cert-validity MONTHS",
        :description => "Default is 24 months",
        :default => "24"

      option :cert_passphrase,
        :short => "-cp PASSWORD",
        :long => "--cert-passphrase PASSWORD",
        :description => "Default is winrmcertgen",
        :default => "winrmcertgen"

      def generate_keypair
        OpenSSL::PKey::RSA.new(config[:key_length].to_i)
      end

      def generate_certificate rsa_key
        @hostname = "*"
        if config[:domain]
          @hostname = "*." + config[:domain]
        end

        #Create a self-signed X509 certificate from the rsa_key (unencrypted)
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = Random.rand(65534) + 1 # 2 digit byte range random number for better security aspect

        cert.subject = OpenSSL::X509::Name.parse "/CN=#{@hostname}"
        cert.issuer = cert.subject
        cert.public_key = rsa_key.public_key
        cert.not_before = Time.now
        cert.not_after = cert.not_before + 2 * 365 * config[:cert_validity].to_i * 60 * 60 # 2 years validity
        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
        cert.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
        cert.add_extension(ef.create_extension("extendedKeyUsage", "1.3.6.1.5.5.7.3.1", false))
        cert.sign(rsa_key, OpenSSL::Digest::SHA1.new)
        @thumbprint = OpenSSL::Digest::SHA1.new(cert.to_der)
        cert
      end

      def write_certificate_to_file cert, file_path, rsa_key
        File.open(file_path + ".pem", "wb") { |f| f.print cert.to_pem }
        pfx = OpenSSL::PKCS12.create('#{config[:cert_passphrase]}', 'winrmcert', rsa_key, cert)
        File.open(file_path + ".pfx", "wb") { |f| f.print pfx.to_der }
        File.open(file_path + ".der", "wb") { |f| f.print Base64.strict_encode64(pfx.to_der) }
      end
        
      def run
        STDOUT.sync = STDERR.sync = true
        file_path = "winrmcert"
        if config[:output_file]
          file_path = config[:output_file].split(".")[0]
        end

        begin
          rsa_key = generate_keypair
          cert = generate_certificate rsa_key
          write_certificate_to_file cert, file_path, rsa_key
          ui.info "Generated Certificates:\n PKCS12 FORMAT: #{file_path}.pfx\n BASE64 ENCODED: #{file_path}.der\n REQUIRED FOR CLIENT: #{file_path}.pem"
          ui.info "Certificate Thumbprint: #{@thumbprint.to_s.upcase}"
        rescue => e
          puts "ERROR: + #{e}"
        end
      end

    end
  end
end

