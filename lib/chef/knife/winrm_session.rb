#
# Author:: Steven Murawski <smurawski@chef.io>
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

require 'chef/application'
require 'winrm'

class Chef
  class Knife
    class WinrmSession
      attr_reader :host, :endpoint, :port, :output, :error, :exit_code

      def initialize(options)
        configure_proxy

        @host = options[:host]
        @port = options[:port]
        url = "#{options[:host]}:#{options[:port]}/wsman"
        scheme = options[:transport] == :ssl ? 'https' : 'http'
        @endpoint = "#{scheme}://#{url}"

        opts = Hash.new
        opts = {:user => options[:user], :pass => options[:password], :basic_auth_only => options[:basic_auth_only], :disable_sspi => options[:disable_sspi], :no_ssl_peer_verification => options[:no_ssl_peer_verification], :ssl_peer_fingerprint => options[:ssl_peer_fingerprint]}
        options[:transport] == :kerberos ? opts.merge!({:service => options[:service], :realm => options[:realm], :keytab => options[:keytab]}) : opts.merge!({:ca_trust_path => options[:ca_trust_path]})

        Chef::Log.debug("WinRM::WinRMWebService options: #{opts}")
        Chef::Log.debug("Endpoint: #{endpoint}")
        Chef::Log.debug("Transport: #{options[:transport]}")

        @winrm_session = WinRM::WinRMWebService.new(@endpoint, options[:transport], opts)
        transport = @winrm_session.instance_variable_get(:@xfer)
        http_client = transport.instance_variable_get(:@httpcli)
        Chef::HTTP::DefaultSSLPolicy.new(http_client.ssl_config).set_custom_certs
        @winrm_session.set_timeout(options[:operation_timeout]) if options[:operation_timeout]
      end

      def relay_command(command)
        command_exec = WinRM::CommandExecutor.new(@winrm_session)
        shell_id = command_exec.open
        session_result = command_exec.run_cmd(command)
        get_output(session_result[:data])
        Chef::Log.debug("#{@host}[#{shell_id}] => :run_cmd[#{command}]")
        @exit_code = session_result[:exitcode]
        command_exec.close
        Chef::Log.debug("#{@host}[#{shell_id}] => :shell_close")
        session_result
      end

      private

      def print_data(host, data, color = :cyan)
        if data =~ /\n/
          data.split(/\n/).each { |d| print_data(host, d, color) }
        elsif !data.nil?
          print Chef::Knife::Winrm.ui.color(host, color)
          puts " #{data}"
        end
      end

      def get_output(data)
        data.each do |out, error|
          print_data(@host, out) if out
          print_data(@host, error, :red) if error
        end
      end

      def configure_proxy
        if Chef::Config.respond_to?(:export_proxies)
          Chef::Config.export_proxies
        else
          Chef::Application.new.configure_proxy_environment_variables
        end
      end
    end
  end
end
