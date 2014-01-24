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
require 'chef/knife/certgen'
require 'openssl'

describe Chef::Knife::Certgen do
  before(:all) do
    @certgen = Chef::Knife::Certgen.new
  end

  it "generates RSA key pair" do
    @certgen.config[:key_length] = 2048
    key = @certgen.generate_keypair
    key.should be_instance_of OpenSSL::PKey::RSA
  end

  it "generates X509 certificate" do
    @certgen.config[:domain] = "test.com"
    @certgen.config[:cert_validity] = "24"
    key = @certgen.generate_keypair
    certificate = @certgen.generate_certificate key
    certificate.should be_instance_of OpenSSL::X509::Certificate
  end

  it "writes certificate to file" do
    pending
    File.should_receive(:open).exactly(:three).times
    OpenSSL::PKCS12.stub(:create)
    cert = double(OpenSSL::X509::Certificate.new)
    cert.stub(:to_pem)
    key = double(OpenSSL::PKey::RSA.new)
    @certgen.write_certificate_to_file cert, "test", key
  end

  it "creates certificate" do
    @certgen.config[:output_file] = nil
    @certgen.should_receive(:generate_keypair)
    @certgen.should_receive(:generate_certificate)
    @certgen.should_receive(:write_certificate_to_file)
    @certgen.ui.should_receive(:info).with("Generated Certificates:\n PKCS12 FORMAT: winrmcert.pfx\n BASE64 ENCODED: winrmcert.der\n REQUIRED FOR CLIENT: winrmcert.pem")
    @certgen.thumbprint = "TEST_THUMBPRINT"
    @certgen.ui.should_receive(:info).with("Certificate Thumbprint: TEST_THUMBPRINT")
    @certgen.run
  end

end  
