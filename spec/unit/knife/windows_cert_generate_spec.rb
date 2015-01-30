#
# Author:: Mukta Aphale <mukta.aphale@clogeny.com>
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

require 'spec_helper'
require 'chef/knife/windows_cert_generate'
require 'openssl'

describe Chef::Knife::WindowsCertGenerate do
  before(:all) do
    @certgen = Chef::Knife::WindowsCertGenerate.new
  end

  it "generates RSA key pair" do
    @certgen.config[:key_length] = 2048
    key = @certgen.generate_keypair
    expect(key).to be_instance_of OpenSSL::PKey::RSA
  end

  it "generates X509 certificate" do
    @certgen.config[:domain] = "test.com"
    @certgen.config[:cert_validity] = "24"
    key = @certgen.generate_keypair
    certificate = @certgen.generate_certificate key
    expect(certificate).to be_instance_of OpenSSL::X509::Certificate
  end

  it "writes certificate to file" do
    expect(File).to receive(:open).exactly(3).times
    cert = double(OpenSSL::X509::Certificate.new)
    key = double(OpenSSL::PKey::RSA.new)
    @certgen.config[:cert_passphrase] = "password"
    expect(OpenSSL::PKCS12).to receive(:create).with("password", "winrmcert", key, cert)
    @certgen.write_certificate_to_file cert, "test", key
  end

  it "creates certificate" do
    @certgen.config[:output_file] = 'winrmcert'
    expect(@certgen).to receive(:generate_keypair)
    expect(@certgen).to receive(:generate_certificate)
    expect(@certgen).to receive(:write_certificate_to_file)
    expect(@certgen.ui).to receive(:info).with("Generated Certificates:")
    expect(@certgen.ui).to receive(:info).with("- winrmcert.pfx - PKCS12 format keypair. Contains both the public and private keys, usually used on the server.")
    expect(@certgen.ui).to receive(:info).with("- winrmcert.b64 - Base64 encoded PKCS12 keypair. Contains both the public and private keys, for upload to the Cloud REST API. e.g. Azure")
    expect(@certgen.ui).to receive(:info).with("- winrmcert.pem - Base64 encoded public certificate only. Required by the client to connect to the server.")
    @certgen.thumbprint = "TEST_THUMBPRINT"
    expect(@certgen.ui).to receive(:info).with("Certificate Thumbprint: TEST_THUMBPRINT")
    @certgen.run
  end
end
