#
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

require 'chef/knife'
require 'chef/knife/winrm_base'
require 'openssl'
require 'socket'

class Chef
  class Knife
    class Certgen < Knife

      include Chef::Knife::WinrmBase

      deps do
        require 'readline'
        require 'chef/search/query'
        require 'em-winrm'
      end

      attr_accessor :thumbprint, :hostname

      banner "knife certgen (options)"

      option :hostname,
        :short => "-h HOSTNAME",
        :long => "--hostname HOSTNAME",
        :description => "You need to specify the hostname of the server if you want to generate the certificate"

      option :certificate,
        :short => "-c PATH",
        :long => "--certificate PATH",
        :description => "QUERY is a space separated list of servers"

      def generate_keypair
        OpenSSL::PKey::RSA.new(1024)
      end

      def generate_certificate rsa_key
        @hostname = Socket.gethostname

        #Create a self-signed X509 certificate from the rsa_key (unencrypted)
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = Random.rand(65534) + 1 # 2 digit byte range random number for better security aspect

        cert.subject = OpenSSL::X509::Name.parse "/CN=#{hostname}"
        cert.issuer = cert.subject
        cert.public_key = rsa_key.public_key
        cert.not_before = Time.now
        cert.not_after = cert.not_before + 2 * 365 * 24 * 60 * 60 # 2 years validity
        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
        cert.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
        cert.add_extension(ef.create_extension("extendedKeyUsage", "1.3.6.1.5.5.7.3.1", false))
        cert.sign(rsa_key, OpenSSL::Digest::SHA1.new)
        @thumbprint = OpenSSL::Digest::SHA1.new(cert.to_der)
        OpenSSL::PKCS12.create('winrmcertgen', '', rsa_key, cert)
      end

      def write_certificate_to_file pfx, file_path
        File.open(file_path, "wb") { |f| f.print pfx.to_der }
      end
        
      def add_cert_to_store file_path
        #not able to use the file_path in this command
        exec 'powershell.exe -ExecutionPolicy RemoteSigned -Command "certutil -p \'winrmcertgen\' -importPFX winrm_cert.pfx AT_KEYEXCHANGE "'
      end
        
      def create_winrm_https_listener hostname, thumbprint
        exec 'cmd.exe winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="#{hostname}";CertificateThumbprint="#{thumbprint}";Port="5986"}'
      end

      def delete_winrm_http_listener
      end

      def run
        STDOUT.sync = STDERR.sync = true
        file_path = "winrm_cert.pfx"       

        begin
          rsa_key = generate_keypair
          pfx = generate_certificate rsa_key
          write_certificate_to_file pfx, file_path
          add_cert_to_store file_path
          create_winrm_https_listener @hostname, @thumbprint.to_s
          delete_winrm_http_listener  
        rescue Error => e
          puts "ERROR: + #{e}"
        end
      end

    end
  end
end

