# Author:: Mukta Aphale (<mukta.aphale@clogeny.com>)
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
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

require "chef/knife"
require_relative "helpers/winrm_base"
require "chef/mixin/powershell_exec"

class Chef
  class Knife
    class WindowsCertGenerate < Knife

      include Chef::Mixin::PowershellExec

      attr_accessor :thumbprint, :hostname

      banner "knife windows cert generate -h HOST_NAME (options)"

      deps do
        require "openssl" unless defined?(OpenSSL)
        require "socket" unless defined?(Socket)
      end

      option :hostname,
        short: "-H HOSTNAME",
        long: "--hostname HOSTNAME",
        description: "Use to specify the hostname for the listener.
        For example, --hostname something.mydomain.com or *.mydomain.com.",
        required: true

      option :output_file,
        short: "-o PATH",
        long: "--output-file PATH",
        description: "Specifies the file path at which to generate the 3 certificate files of type .pfx, .b64, and .pem. If you omit this option we use c:\\chef\\cache\\chef-<hostname> as the filename for each certificate type"

      option :key_length,
        short: "-k LENGTH",
        long: "--key-length LENGTH",
        description: "Default is 2048",
        default: "2048"

      option :cert_validity,
        long: "--cert-validity MONTHS",
        description: "Default is 24 months",
        default: "24"

      option :cert_passphrase,
        long: "--cert-passphrase PASSWORD",
        description: "Password for certificate."

      option :store_in_certstore,
        long: "--store_in_certstore true",
        description: "Tells knife to store the password for your certificates in the Windows Registry for later retrieval."

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

      def generate_certificate(rsa_key)
        @hostname = config[:hostname] if config[:hostname]

        # Create a self-signed X509 certificate from the rsa_key (unencrypted)
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
        cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
        cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))
        cert.add_extension(ef.create_extension("extendedKeyUsage", "1.3.6.1.5.5.7.3.1", false))
        cert.sign(rsa_key, OpenSSL::Digest.new("SHA1"))
        @thumbprint = OpenSSL::Digest::SHA1.new(cert.to_der)
        cert
      end

      def write_certificate_to_file(cert, file_path, rsa_key, store_key)
        File.open(file_path + ".pem", "wb") { |f| f.print cert.to_pem }

        config[:cert_passphrase] = prompt_for_passphrase unless config[:cert_passphrase]

        if store_key == true
          set_local_password(config[:cert_passphrase])
        end

        pfx = OpenSSL::PKCS12.create("#{config[:cert_passphrase]}", file_path, rsa_key, cert)
        File.open(file_path + ".pfx", "wb") { |f| f.print pfx.to_der }
        File.open(file_path + ".b64", "wb") { |f| f.print Base64.strict_encode64(pfx.to_der) }
      end

      # in the world of No Certs On Disk, we store a password for a p12/pfx in Keychain or the Registry. A p12/Pfx MUST have a password associated with it because it holds a private key
      # Here we check to see if that password is already set.
      def check_for_local_password
        if ChefUtils.windows?
          powershell_code = <<-CHECKFORPASSWORD
            Try {
              $localpass =  Get-ItemPropertyValue -Path "HKLM:\\Software\Progress\Authenticator" -Name "PfxPass" -ErrorAction Stop
              return $localpass
            }
            Catch {
              return $false
            }
          CHECKFORPASSWORD
          powershell_exec!(powershell_code).result
        elsif ChefUtils.macos?
          return
        end
      end

      def set_local_password(password)
        print "The password you just specified is being stored in the Registry. It will be used as the default until explicitly updated\n"
        more_powershell_code = <<-SETTHEPASSWORD
        $my_pwd = ConvertTo-SecureString -String "#{password}" -Force -AsPlainText;
        if (-not (Test-Path HKLM:\\SOFTWARE\\Progress)){
          New-Item -Path "HKLM:\\SOFTWARE\\Progress\\Authenticator" -Force
          New-ItemProperty  -path "HKLM:\\SOFTWARE\\Progress\\Authenticator" -name "PfxPass" -value $my_pwd -PropertyType String
        }
        else{
          Set-ItemProperty  -path "HKLM:\\SOFTWARE\\Progress\\Authenticator" -name "PfxPass" -value $my_pwd
        }

        SETTHEPASSWORD
        powershell_exec!(more_powershell_code)
      end

      def certificates_already_exist?(file_path)
        certs_exists = false
        %w{pem pfx b64}.each do |extn|
          if File.exist?("#{file_path}.#{extn}")
            certs_exists = true
            break
          end
        end

        if certs_exists
          begin
            confirm("Do you really want to overwrite existing certificates")
          rescue SystemExit # Need to handle this as confirming with N/n raises SystemExit exception
            exit!
          end
        end
      end

      def run
        STDOUT.sync = STDERR.sync = true

        # takes user specified first cli value as a destination file path for generated cert.
        # allowing for output_file to be ommitted
        if config[:output_file] == nil?
          config[:output_file] = File.join(::Chef::Config[:file_cache_path], "chef-#{config[:hostname]}")
        end

        file_path = @name_args.empty? ? config[:output_file].sub(/\.(\w+)$/, "") : @name_args.first

        # check if certs already exists at given file path
        certificates_already_exist? file_path

        if config[:store_in_certstore] == "true" || config[:store_in_certstore] == "True" || config[:store_in_certstore] == "TRUE"
          store_key = true
        else
          store_key = false
        end

        begin
          filename = File.basename(file_path)
          rsa_key = generate_keypair
          cert = generate_certificate rsa_key
          write_certificate_to_file cert, file_path, rsa_key, store_key
          ui.info "Generated Certificates:"
          ui.info "- #{filename}.pfx - PKCS12 format key pair. Contains public and private keys, can be used with an SSL server."
          ui.info "- #{filename}.b64 - Base64 encoded PKCS12 key pair. Contains public and private keys, used by some cloud provider API's to configure SSL servers."
          ui.info "- #{filename}.pem - Base64 encoded public certificate only. Required by the client to connect to the server."
          ui.info "Certificate Thumbprint: #{@thumbprint.to_s.upcase}"
        rescue => e
          puts "ERROR: + #{e}"
        end
      end

    end
  end
end
