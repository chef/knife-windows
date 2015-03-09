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
    class WindowsCertGenerate < Knife

      attr_accessor :thumbprint, :hostname

      banner "knife windows cert generate FILE_PATH (options)"

      option :hostname,
        :short => "-H HOSTNAME",
        :long => "--hostname HOSTNAME",
        :description => "By default hostname is *. If user wants to give his fqdn as the hostname
        then he must specify the hostname as: --hostname 'something.mydomain.com'. User can also give wildcard
        as '*.mydomain.com'"

      option :output_file,
        :short => "-o PATH",
        :long => "--output-file PATH",
        :description => "By default 3 files will be generated in the current folder as winrmcert.pfx,
        winrmcert.b64 and winrmcert.pem. You can specify alternate file path and filename using this option.
        Eg: --output-file /home/.winrm/server_cert. This will create 3 files at path '/home/.winrm/'
        with name 'server_cert'",
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
        :description => "Password for certificate."

      def generate_keypair
        OpenSSL::PKey::RSA.new(config[:key_length].to_i)
      end

      def prompt_for_passphrase
        passphrase = ""
        begin
          print "Passphrases do not match.  Try again.\n" unless passphrase.empty?
          print "Enter certificate passphrase (empty for no passphrase):"
          passphrase = STDIN.gets
          return passphrase.strip if passphrase == "\n"
          print "Enter same passphrase again:"
          confirm_passphrase = STDIN.gets
        end until passphrase == confirm_passphrase
        passphrase.strip
      end

      def generate_certificate rsa_key
        @hostname = "*"
        @hostname = config[:hostname] if config[:hostname]

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
        config[:cert_passphrase] = prompt_for_passphrase unless config[:cert_passphrase]
        pfx = OpenSSL::PKCS12.create("#{config[:cert_passphrase]}", "winrmcert", rsa_key, cert)
        File.open(file_path + ".pfx", "wb") { |f| f.print pfx.to_der }
        File.open(file_path + ".b64", "wb") { |f| f.print Base64.strict_encode64(pfx.to_der) }
      end

      def run
        STDOUT.sync = STDERR.sync = true

        # takes user specified first cli value as a destination file path for generated cert.
        file_path = @name_args.empty? ? config[:output_file].sub(/\.(\w+)$/,'') : @name_args.first

        begin
          rsa_key = generate_keypair
          cert = generate_certificate rsa_key
          write_certificate_to_file cert, file_path, rsa_key
          ui.info "Generated Certificates:"
          ui.info "- #{file_path}.pfx - PKCS12 format keypair. Contains both the public and private keys, usually used on the server."
          ui.info "- #{file_path}.b64 - Base64 encoded PKCS12 keypair. Contains both the public and private keys, for upload to the Cloud REST API. e.g. Azure"
          ui.info "- #{file_path}.pem - Base64 encoded public certificate only. Required by the client to connect to the server."
          ui.info "Certificate Thumbprint: #{@thumbprint.to_s.upcase}"
        rescue => e
          puts "ERROR: + #{e}"
        end
      end

    end
  end
end

