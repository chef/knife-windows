#
# Author:: Steven Murawski (<smurawski@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

describe Chef::Knife::WsmanTest do
  before(:all) do
    Chef::Config.reset
  end

  context 'when testing the WSMAN endpoint' do
    let(:wsman_tester) {Chef::Knife::WsmanTest.new(['-m', 'localhost'])}
    context 'and the service does not respond' do 
      error_message = 'A connection attempt failed because the connected party did not properly respond after a period of time.'      

      it 'returns an object with an error message' do
        http_client_mock = HTTPClient.new
        allow(HTTPClient).to receive(:new).and_return(http_client_mock)
        allow(http_client_mock).to receive(:post).and_raise(Exception.new(error_message))
        expect(wsman_tester).to receive(:output).with(duck_type(:error_message)) 
        wsman_tester.run       
      end
    end

    context 'and the target node is Windows Server 2008 R2' do
      response_body = <<-RESPONSEXML
      <s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Header/><s:Body><wsmid:IdentifyResponse xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><wsmid:ProtocolVersion>http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd</wsmid:ProtocolVersion><wsmid:ProductVendor>Microsoft Corporation</wsmid:ProductVendor><wsmid:ProductVersion>OS: 0.0.0 SP: 0.0 Stack: 2.0</wsmid:ProductVersion></wsmid:IdentifyResponse></s:Body></s:Envelope>
      RESPONSEXML
      before(:each) do
        http_client_mock = HTTPClient.new
        http_response_mock = HTTP::Message.new_response(response_body)                
        allow(HTTPClient).to receive(:new).and_return(http_client_mock)
        allow(http_client_mock).to receive(:post).and_return(http_response_mock)
      end

      it 'identifies the stack of the product version as 2.0 ' do        
        expect(wsman_tester).to receive(:output) do |output|
          expect(output.product_version).to  eq 'OS: 0.0.0 SP: 0.0 Stack: 2.0'
        end
        wsman_tester.run   
      end

      it 'identifies the protocol version as the current DMTF standard' do
        expect(wsman_tester).to receive(:output) do |output|
          expect(output.protocol_version).to  eq 'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd'
        end
        wsman_tester.run 
      end

      it 'identifies the vendor as the Microsoft Corporation' do
        expect(wsman_tester).to receive(:output) do |output|
          expect(output.product_vendor).to  eq 'Microsoft Corporation'
        end
        wsman_tester.run  
      end
    end

    context 'and the target node is Windows Server 2012 R2' do
      response_body = <<-RESPONSEXML
      <s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Header/><s:Body><wsmid:IdentifyResponse xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><wsmid:ProtocolVersion>http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd</wsmid:ProtocolVersion><wsmid:ProductVendor>Microsoft Corporation</wsmid:ProductVendor><wsmid:ProductVersion>OS: 0.0.0 SP: 0.0 Stack: 3.0</wsmid:ProductVersion></wsmid:IdentifyResponse></s:Body></s:Envelope>
      RESPONSEXML
      before(:each) do
        http_client_mock = HTTPClient.new
        http_response_mock = HTTP::Message.new_response(response_body)                
        allow(HTTPClient).to receive(:new).and_return(http_client_mock)
        allow(http_client_mock).to receive(:post).and_return(http_response_mock)
      end

      it 'identifies the stack of the product version as 3.0 ' do        
        expect(wsman_tester).to receive(:output) do |output|
          expect(output.product_version).to  eq 'OS: 0.0.0 SP: 0.0 Stack: 3.0'
        end
        wsman_tester.run   
      end

      it 'identifies the protocol version as the current DMTF standard' do
        expect(wsman_tester).to receive(:output) do |output|
          expect(output.protocol_version).to  eq 'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd'
        end
        wsman_tester.run 
      end

      it 'identifies the vendor as the Microsoft Corporation' do
        expect(wsman_tester).to receive(:output) do |output|
          expect(output.product_vendor).to  eq 'Microsoft Corporation'
        end
        wsman_tester.run  
      end
    end
  end


end