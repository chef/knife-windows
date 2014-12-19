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

require 'httpclient'
require 'nokogiri'
require 'chef/knife'
require 'chef/knife/winrm_knife_base'
require 'chef/knife/wsman_endpoint'


class Chef
  class Knife
    class WsmanTest < Knife

      include Chef::Knife::WinrmCommandSharedFunctions 

      deps do
        require 'chef/search/query'
      end

      banner "knife wsman test QUERY (options)"

      def run
        @config[:winrm_authentication_protocol] = 'basic'
        configure_session
        verify_wsman_accessiblity_for_nodes        
      end  

      def verify_wsman_accessiblity_for_nodes           
        @winrm_sessions.each do |item|
          Chef::Log.debug("checking for WSMAN availability at #{item.endpoint}")

          xml = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><s:Header/><s:Body><wsmid:Identify/></s:Body></s:Envelope>'
          header = {
            'WSMANIDENTIFY' => 'unauthenticated',
            'Content-Type' => 'application/soap+xml; charset=UTF-8'
          }
          output_object = Chef::Knife::WsmanEndpoint.new(item.host, item.port, item.endpoint)      

          begin
            client = HTTPClient.new
            response = client.post(item.endpoint, xml, header)
          rescue Exception => e
            output_object.error_message = e.message
          else
            output_object.response_status_code = response.status_code 
          end

          if not response.nil? and response.status_code == 200
            doc = Nokogiri::XML response.body   
            namespace = 'http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd'         
            output_object.protocol_version = doc.xpath('//wsmid:ProtocolVersion', 'wsmid' => namespace).text
            output_object.product_version  = doc.xpath('//wsmid:ProductVersion',  'wsmid' => namespace).text
            output_object.product_vendor  = doc.xpath('//wsmid:ProductVendor',   'wsmid' => namespace).text                       
          end

          output(output_object)          
        end        
      end
    end
  end
end
