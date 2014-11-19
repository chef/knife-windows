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
require 'chef/knife/windows_cert_generate'
require 'chef/knife/windows_cert_install'
require 'chef/knife/windows_listener_create'

class Chef
  class Knife
    class Winrm < Knife

      @@ssl_warning_given = false

      class Session
        attr_reader :host, :output, :error, :exit_code
        def initialize(options)
          @host = options[:host]
          url = "#{options[:host]}:#{options[:port]}/wsman"
          scheme = options[:transport] == :ssl ? 'https' : 'http'
          endpoint = "#{scheme}://#{url}"
          opts = Hash.new
          opts = {:user => options[:user], :pass => options[:password], :basic_auth_only => options[:basic_auth_only], :disable_sspi => options[:disable_sspi], :no_ssl_peer_verification => options[:no_ssl_peer_verification]}

          options[:transport] == :kerberos ? opts.merge!({:service => options[:service], :realm => options[:realm], :keytab => options[:keytab]}) : opts.merge!({:ca_trust_path => options[:ca_trust_path]})
          Chef::Log.debug("WinRM::WinRMWebService options: #{opts}")
          Chef::Log.debug("Endpoint: #{endpoint}")
          Chef::Log.debug("Transport: #{options[:transport]}")
          @winrm_session = WinRM::WinRMWebService.new(endpoint, options[:transport], opts)
        end

        def relay_command(command)
          session_result = @winrm_session.cmd(command) do |stdout, stderr|
            @output = stdout
            @error = stderr
          end
          @exit_code = session_result[:exitcode]
        end
      end

      include Chef::Knife::WinrmBase

      deps do
        require 'readline'
        require 'chef/search/query'
        require 'winrm'
      end

      attr_writer :password

      banner "knife winrm QUERY COMMAND (options)"

      option :attribute,
        :short => "-a ATTR",
        :long => "--attribute ATTR",
        :description => "The attribute to use for opening the connection - default is fqdn",
        :default => "fqdn"

      option :returns,
       :long => "--returns CODES",
       :description => "A comma delimited list of return codes which indicate success",
       :default => "0"

      option :manual,
        :short => "-m",
        :long => "--manual-list",
        :boolean => true,
        :description => "QUERY is a space separated list of servers",
        :default => false

       def create_winrm_session(options={})
         session = Chef::Knife::Winrm::Session.new(options)
         @winrm_sessions ||= []
         @winrm_sessions.push(session)
       end

       def print_data(host, data, color = :cyan)
         if data =~ /\n/
           data.split(/\n/).each { |d| print_data(host, d, color) }
         else
           print ui.color(host, color)
           puts " #{data}"
         end
       end

       def relay_winrm_command(command)
         Chef::Log.debug(command)
         @winrm_sessions.each do |s|
           s.relay_command(command)
           print_data(s.host, s.output)
           print_data(s.host, s.error, :red)
         end
       end

      def success_return_codes
        #Redundant if the CLI options parsing occurs
        return [0] unless config[:returns]
        return config[:returns].split(',').collect {|item| item.to_i}
      end

      # TODO: Copied from Knife::Core:GenericPresenter. Should be extracted
      def extract_nested_value(data, nested_value_spec)
        nested_value_spec.split(".").each do |attr|
          if data.nil?
            nil # don't get no method error on nil
          elsif data.respond_to?(attr.to_sym)
            data = data.send(attr.to_sym)
          elsif data.respond_to?(:[])
            data = data[attr]
          else
            data = begin
                     data.send(attr.to_sym)
                   rescue NoMethodError
                     nil
                   end
          end
        end
        ( !data.kind_of?(Array) && data.respond_to?(:to_hash) ) ? data.to_hash : data
      end

      def configure_session

        list = case config[:manual]
               when true
                 @name_args[0].split(" ")
               when false
                 r = Array.new
                 q = Chef::Search::Query.new
                 @action_nodes = q.search(:node, @name_args[0])[0]
                 @action_nodes.each do |item|
                   i = extract_nested_value(item, config[:attribute])
                   r.push(i) unless i.nil?
                 end
                 r
               end
        if list.length == 0
          if @action_nodes.length == 0
            ui.fatal("No nodes returned from search!")
          else
            ui.fatal("#{@action_nodes.length} #{@action_nodes.length > 1 ? "nodes":"node"} found, " +
                     "but does not have the required attribute (#{config[:attribute]}) to establish the connection. " +
                     "Try setting another attribute to open the connection using --attribute.")
          end
          exit 10
        end
        session_from_list(list)
      end

      def session_from_list(list)
        list.each do |item|
          Chef::Log.debug("Adding #{item}")
          session_opts = {}
          session_opts[:user] = locate_config_value(:winrm_user)
          session_opts[:password] = locate_config_value(:winrm_password)
          session_opts[:port] = locate_config_value(:winrm_port)
          session_opts[:keytab] = locate_config_value(:kerberos_keytab_file) if locate_config_value(:kerberos_keytab_file)
          session_opts[:realm] = locate_config_value(:kerberos_realm) if locate_config_value(:kerberos_realm)
          session_opts[:service] = locate_config_value(:kerberos_service) if locate_config_value(:kerberos_service)
          session_opts[:ca_trust_path] = locate_config_value(:ca_trust_file) if locate_config_value(:ca_trust_file)
          session_opts[:operation_timeout] = 1800 # 30 min OperationTimeout for long bootstraps fix for KNIFE_WINDOWS-8
          session_opts[:no_ssl_peer_verification] = no_ssl_peer_verification?(session_opts[:ca_trust_path])
          warn_no_ssl_peer_verification if session_opts[:no_ssl_peer_verification]

          username_contains_domain = session_opts[:user].split("\\").length.eql?(2)

          if username_contains_domain
            # We cannot use basic_auth for domain authentication
            session_opts[:basic_auth_only] = false
          else
            session_opts[:basic_auth_only] = true
          end

          if config.keys.any? {|k| k.to_s =~ /kerberos/ }
            session_opts[:transport] = :kerberos
            session_opts[:basic_auth_only] = false
          else
            session_opts[:transport] = locate_config_value(:winrm_transport).to_sym
            if Chef::Platform.windows? && session_opts[:transport] == :plaintext && negotiate_auth?
              # windows - force only encrypted communication
              require 'winrm-s'
              session_opts[:transport] = :sspinegotiate
              session_opts[:disable_sspi] = false
            else
              session_opts[:disable_sspi] = true
            end
            if session_opts[:user] and
                (not session_opts[:password])
              session_opts[:password] = Chef::Config[:knife][:winrm_password] = config[:winrm_password] = get_password
            end
          end

          session_opts[:host] = item
          create_winrm_session(session_opts)
        end
      end

      def get_password
        @password ||= ui.ask("Enter your password: ") { |q| q.echo = false }
      end

      # Present the prompt and read a single line from the console. It also
      # detects ^D and returns "exit" in that case. Adds the input to the
      # history, unless the input is empty. Loops repeatedly until a non-empty
      # line is input.
      def read_line
        loop do
          command = reader.readline("#{ui.color('knife-winrm>', :bold)} ", true)

          if command.nil?
            command = "exit"
            puts(command)
          else
            command.strip!
          end

          unless command.empty?
            return command
          end
        end
      end

      def reader
        Readline
      end

      def interactive
        puts "WARN: Deprecated functionality. This will not be supported in future knife-windows releases."
        puts "Connected to #{ui.list(session.servers.collect { |s| ui.color(s.host, :cyan) }, :inline, " and ")}"
        puts
        puts "To run a command on a list of servers, do:"
        puts "  on SERVER1 SERVER2 SERVER3; COMMAND"
        puts "  Example: on latte foamy; echo foobar"
        puts
        puts "To exit interactive mode, use 'quit!'"
        puts
        while 1
          command = read_line
          case command
          when 'quit!'
            puts 'Bye!'
            break
          when /^on (.+?); (.+)$/
            raw_list = $1.split(" ")
            server_list = Array.new
            @winrm_sessions.each do |session_server|
              server_list << session_server if raw_list.include?(session_server.host)
            end
            command = $2
            relay_winrm_command(command, server_list)
          else
            relay_winrm_command(command)
          end
        end
      end

      # returns true if winrm_authentication_protocol is 'negotiate'
      def negotiate_auth?
        (Chef::Config[:knife][:winrm_authentication_protocol] || config[:winrm_authentication_protocol]) == "negotiate"
      end

      def validate!
        winrm_auth_protocol = (Chef::Config[:knife][:winrm_authentication_protocol] || config[:winrm_authentication_protocol])
        if winrm_auth_protocol && ! %w{basic negotiate kerberos}.include?(winrm_auth_protocol)
          ui.error "Invalid value for --winrm-authentication-protocol option. Use valid protocol values i.e [basic, negotiate, kerberos]"
          exit 1
        end

        ui.error "The '--winrm-authentication-protocol = negotiate' only supported when this tool is invoked from a Windows-based system." if !Chef::Platform.windows? && negotiate_auth?
      end

      def check_for_errors!
        @winrm_sessions.each do |session|
          session_exit_code = session.exit_code
          unless success_return_codes.include? session_exit_code.to_i
            @exit_code = session_exit_code.to_i
            ui.error "Failed to execute command on #{session.host} return code #{session_exit_code}"
          end
        end
      end

      def run

        STDOUT.sync = STDERR.sync = true

        validate!

        begin
          @longest = 0

          configure_session

          case @name_args[1]
          when "interactive"
            interactive
          else
            relay_winrm_command(@name_args[1..-1].join(" "))

            if config[:returns]
              check_for_errors!
            end

            # Knife seems to ignore the return value of this method,
            # so we exit to force the process exit code for this
            # subcommand if returns is set
            exit @exit_code if @exit_code && @exit_code != 0
            @exit_code || 0
          end
        rescue WinRM::WinRMHTTPTransportError => e
          case e.message
          when /401/
            if ! config[:suppress_auth_failure]
              # Display errors if the caller hasn't opted to retry
              ui.error "Failed to authenticate to #{@name_args[0].split(" ")} as #{locate_config_value(:winrm_user)}"
              ui.info "Response: #{e.message}"
              ui.info "Hint: Please check winrm configuration 'winrm get winrm/config/service' AllowUnencrypted flag on remote server."
              raise e
            end
            @exit_code = 401
          else
            raise e
          end
        end
      end

      private

      def no_ssl_peer_verification?(ca_trust_path)
        ca_trust_path.nil? && (config[:winrm_ssl_verify_mode] == :verify_none)
      end

      def warn_no_ssl_peer_verification
        if ! @@ssl_warning_given
          @@ssl_warning_given = true
          ui.warn(<<-WARN)
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
SSL validation of HTTPS requests for the WinRM transport is disabled. HTTPS WinRM
connections are still encrypted, but knife is not able to detect forged replies
or spoofing attacks.

To fix this issue add an entry like this to your knife configuration file:

```
  # Verify all WinRM HTTPS connections (default, recommended)
  knife[:winrm_ssl_verify_mode] = :verify_peer
```
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
WARN
        end
      end
    end
  end
end

