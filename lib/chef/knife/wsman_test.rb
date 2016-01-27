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
        error_count = 0
        @winrm_sessions.each do |item|
          Chef::Log.debug("checking for WSMAN availability at #{item.endpoint}")

          xml = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><s:Header/><s:Body><wsmid:Identify/></s:Body></s:Envelope>'
          header = {
            'WSMANIDENTIFY' => 'unauthenticated',
            'Content-Type' => 'application/soap+xml; charset=UTF-8'
          }
          output_object = Chef::Knife::WsmanEndpoint.new(item.host, item.port, item.endpoint)
          error_message = nil
          begin
            client = HTTPClient.new
            response = client.post(item.endpoint, xml, header)
          rescue Exception => e
            error_message = e.message
          else
            ui.msg "Connected successfully to #{item.host} at #{item.endpoint}."
            output_object.response_status_code = response.status_code
          end

          if response.nil? || output_object.response_status_code != 200
            error_message = "No valid WSMan endoint listening at #{item.endpoint}."
          else
            doc = REXML::Document.new(response.body)
            output_object.protocol_version = search_xpath(doc, "//wsmid:ProtocolVersion")
            output_object.product_version  = search_xpath(doc, "//wsmid:ProductVersion")
            output_object.product_vendor  = search_xpath(doc, "//wsmid:ProductVendor")
            if output_object.protocol_version.to_s.strip.length == 0
              error_message = "Endpoint #{item.endpoint} on #{item.host} does not appear to be a WSMAN endpoint. Response body was #{response.body}"
            end
          end

          unless error_message.nil?
            ui.warn "Failed to connect to #{item.host} at #{item.endpoint}."
            output_object.error_message = error_message
            error_count += 1
          end

          if config[:verbosity] >= 1
            output(output_object)
          end
        end
        if error_count > 0
          ui.error "Failed to connect to #{error_count} nodes."
          exit 1
        end
      end

      def search_xpath(document, property_name)
        result = REXML::XPath.match(document, property_name)
        result[0].nil? ? '' : result[0].text
      end
    end
  end
end
