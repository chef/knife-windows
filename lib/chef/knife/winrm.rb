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
require 'chef/knife/winrm_knife_base'
require 'chef/knife/windows_cert_generate'
require 'chef/knife/windows_cert_install'
require 'chef/knife/windows_listener_create'
require 'chef/knife/winrm_session'
require 'chef/knife/knife_windows_base'

class Chef
  class Knife
    class Winrm < Knife 

      include Chef::Knife::WinrmCommandSharedFunctions     
      include Chef::Knife::KnifeWindowsBase

      FAILED_BASIC_HINT ||= "Hint: Please check winrm configuration 'winrm get winrm/config/service' AllowUnencrypted flag on remote server."
      FAILED_NOT_BASIC_HINT ||= <<-eos.gsub /^\s+/, ""
        Hint: Make sure to prefix domain usernames with the correct domain name.
        Hint: Local user names should be prefixed with computer name or IP address.
        EXAMPLE: my_domain\\user_namer
      eos

      deps do
        require 'readline'
        require 'chef/search/query'
      end

      attr_writer :password

      banner "knife winrm QUERY COMMAND (options)"      

      option :returns,
       :long => "--returns CODES",
       :description => "A comma delimited list of return codes which indicate success",
       :default => "0"      

      def run
        STDOUT.sync = STDERR.sync = true        

        configure_session
        execute_remote_command        
      end

      def execute_remote_command
        begin
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
        rescue WinRM::WinRMHTTPTransportError, WinRM::WinRMAuthorizationError => e
          if authorization_error?(e)
            if ! config[:suppress_auth_failure]
              # Display errors if the caller hasn't opted to retry
              ui.error "Failed to authenticate to #{@name_args[0].split(" ")} as #{locate_config_value(:winrm_user)}"
              ui.info "Response: #{e.message}"
              ui.info get_failed_authentication_hint
              raise e
            end
            @exit_code = 401
          else
            raise e
          end
        end
      end

      def relay_winrm_command(command)
        Chef::Log.debug(command)
        @winrm_sessions.each do |s|
          s.relay_command(command)
        end
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

      private

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

      def check_for_errors!
        @winrm_sessions.each do |session|
          session_exit_code = session.exit_code
          unless success_return_codes.include? session_exit_code.to_i
            @exit_code = session_exit_code.to_i
            ui.error "Failed to execute command on #{session.host} return code #{session_exit_code}"
          end
        end
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

      def authorization_error?(exception)
        exception.is_a?(WinRM::WinRMAuthorizationError) ||
          exception.message =~ /401/
      end

      def success_return_codes
        #Redundant if the CLI options parsing occurs
        return [0] unless config[:returns]
        return @success_return_codes ||= config[:returns].split(',').collect {|item| item.to_i}
      end

      def get_failed_authentication_hint
        if @session_opts[:basic_auth_only]
          FAILED_BASIC_HINT
        else
          FAILED_NOT_BASIC_HINT
        end
      end
    end
  end
end

