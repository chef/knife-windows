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
    let(:wsman_tester) { Chef::Knife::WsmanTest.new(['-m', 'localhost']) }
    let(:http_client_mock) {HTTPClient.new}

    before(:each) do
      wsman_tester.config[:verbosity] = 0
      allow(HTTPClient).to receive(:new).and_return(http_client_mock)
    end

    context 'and the service does not respond' do
      error_message = 'A connection attempt failed because the connected party did not properly respond after a period of time.'

      before(:each) do
        allow(HTTPClient).to receive(:new).and_return(http_client_mock)
        allow(http_client_mock).to receive(:post).and_raise(Exception.new(error_message))
      end

      it 'exits with a status code of 1' do
        expect(wsman_tester).to receive(:exit).with(1)
        wsman_tester.run
      end

      it 'writes a warning message for each node it fails to connect to' do
        expect(wsman_tester.ui).to receive(:warn)
        expect(wsman_tester).to receive(:exit).with(1)
        wsman_tester.run
      end

      it 'writes an error message if it fails to connect to any nodes' do
        expect(wsman_tester.ui).to receive(:error)
        expect(wsman_tester).to receive(:exit).with(1)
        wsman_tester.run
      end
    end

    context 'and the service responds' do
      context 'successfully' do
        it 'writes a message about a successful connection' do
          response_body = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Header/><s:Body><wsmid:IdentifyResponse xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><wsmid:ProtocolVersion>http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd</wsmid:ProtocolVersion><wsmid:ProductVendor>Microsoft Corporation</wsmid:ProductVendor><wsmid:ProductVersion>OS: 0.0.0 SP: 0.0 Stack: 2.0</wsmid:ProductVersion></wsmid:IdentifyResponse></s:Body></s:Envelope>'
          http_response_mock = HTTP::Message.new_response(response_body)
          allow(http_client_mock).to receive(:post).and_return(http_response_mock)
          expect(wsman_tester.ui).to receive(:msg)
          wsman_tester.run
        end
      end

      context 'with an invalid body' do
        it 'warns for a failed connection and exit with a status of 1' do
          response_body = 'I am invalid'
          http_response_mock = HTTP::Message.new_response(response_body)
          allow(http_client_mock).to receive(:post).and_return(http_response_mock)
          expect(wsman_tester.ui).to receive(:warn)
          expect(wsman_tester.ui).to receive(:error)
          expect(wsman_tester).to receive(:exit).with(1)
          wsman_tester.run
        end
      end

      context 'with a non-200 code' do
        it 'warns for a failed connection and exits with a status of 1' do
          http_response_mock = HTTP::Message.new_response('')
          http_response_mock.status = 404
          allow(http_client_mock).to receive(:post).and_return(http_response_mock)
          expect(wsman_tester.ui).to receive(:warn)
          expect(wsman_tester.ui).to receive(:error)
          expect(wsman_tester).to receive(:exit).with(1)
          wsman_tester.run
        end
      end
    end
  end

  context 'when testing the WSMAN endpoint with verbose output' do
    let(:wsman_tester_verbose) { Chef::Knife::WsmanTest.new(['-m', 'localhost']) }
    let(:http_client_mock_verbose) {HTTPClient.new}

    before(:each) do
      allow(HTTPClient).to receive(:new).and_return(http_client_mock_verbose)
      wsman_tester_verbose.config[:verbosity] = 1
    end

    context 'and the service does not respond' do
      it 'returns an object with an error message' do
        error_message = 'A connection attempt failed because the connected party did not properly respond after a period of time.'
        allow(http_client_mock_verbose).to receive(:post).and_raise(Exception.new(error_message))
        expect(wsman_tester_verbose).to receive(:output).with(duck_type(:error_message))
        expect(wsman_tester_verbose).to receive(:exit).with(1)
        wsman_tester_verbose.run
      end
    end

    context 'and the target node is Windows Server 2008 R2' do
      before(:each) do
        ws2008r2_response_body = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Header/><s:Body><wsmid:IdentifyResponse xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><wsmid:ProtocolVersion>http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd</wsmid:ProtocolVersion><wsmid:ProductVendor>Microsoft Corporation</wsmid:ProductVendor><wsmid:ProductVersion>OS: 0.0.0 SP: 0.0 Stack: 2.0</wsmid:ProductVersion></wsmid:IdentifyResponse></s:Body></s:Envelope>'
        http_response_mock = HTTP::Message.new_response(ws2008r2_response_body)
        allow(http_client_mock_verbose).to receive(:post).and_return(http_response_mock)
      end

      it 'identifies the stack of the product version as 2.0 ' do
        expect(wsman_tester_verbose).to receive(:output) do |output|
          expect(output.product_version).to  eq 'OS: 0.0.0 SP: 0.0 Stack: 2.0'
        end
        wsman_tester_verbose.run
      end

      it 'identifies the protocol version as the current DMTF standard' do
        expect(wsman_tester_verbose).to receive(:output) do |output|
          expect(output.protocol_version).to  eq 'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd'
        end
        wsman_tester_verbose.run
      end

      it 'identifies the vendor as the Microsoft Corporation' do
        expect(wsman_tester_verbose).to receive(:output) do |output|
          expect(output.product_vendor).to  eq 'Microsoft Corporation'
        end
        wsman_tester_verbose.run
      end
    end

    context 'and the target node is Windows Server 2012 R2' do
      before(:each) do
        ws2012_response_body = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Header/><s:Body><wsmid:IdentifyResponse xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><wsmid:ProtocolVersion>http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd</wsmid:ProtocolVersion><wsmid:ProductVendor>Microsoft Corporation</wsmid:ProductVendor><wsmid:ProductVersion>OS: 0.0.0 SP: 0.0 Stack: 3.0</wsmid:ProductVersion></wsmid:IdentifyResponse></s:Body></s:Envelope>'
        http_response_mock = HTTP::Message.new_response(ws2012_response_body)
        allow(http_client_mock_verbose).to receive(:post).and_return(http_response_mock)
      end

      it 'identifies the stack of the product version as 3.0 ' do
        expect(wsman_tester_verbose).to receive(:output) do |output|
          expect(output.product_version).to  eq 'OS: 0.0.0 SP: 0.0 Stack: 3.0'
        end
        wsman_tester_verbose.run
      end

      it 'identifies the protocol version as the current DMTF standard' do
        expect(wsman_tester_verbose).to receive(:output) do |output|
          expect(output.protocol_version).to  eq 'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd'
        end
        wsman_tester_verbose.run
      end

      it 'identifies the vendor as the Microsoft Corporation' do
        expect(wsman_tester_verbose).to receive(:output) do |output|
          expect(output.product_vendor).to  eq 'Microsoft Corporation'
        end
        wsman_tester_verbose.run
      end
    end
  end
end