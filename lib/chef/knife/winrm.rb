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

class Chef
  class Knife
    class Winrm < Knife

      include Chef::Knife::WinrmBase

      deps do
        require 'readline'
        require 'chef/search/query'
        require 'em-winrm'
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
       :default => nil,
       :proc => Proc.new { |codes|
         Chef::Config[:knife][:returns] = codes.split(',').collect {|item| item.to_i} }

      option :manual,
        :short => "-m",
        :long => "--manual-list",
        :boolean => true,
        :description => "QUERY is a space separated list of servers",
        :default => false

      def session
        session_opts = {}
        session_opts[:logger] = Chef::Log.logger if Chef::Log.level == :debug
        @session ||= begin
          s = EventMachine::WinRM::Session.new(session_opts)
          s.on_output do |host, data|
            print_data(host, data)
          end
          s.on_error do |host, err|
            print_data(host, err, :red)
          end
          s.on_command_complete do |host|
            host = host == :all ? 'All Servers' : host
            Chef::Log.debug("command complete on #{host}")
          end
          s
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
          session_opts[:user] = config[:winrm_user] = Chef::Config[:knife][:winrm_user] || config[:winrm_user]
          session_opts[:password] = config[:winrm_password] = Chef::Config[:knife][:winrm_password] || config[:winrm_password]
          session_opts[:port] = Chef::Config[:knife][:winrm_port] || config[:winrm_port]
          session_opts[:keytab] = Chef::Config[:knife][:kerberos_keytab_file] if Chef::Config[:knife][:kerberos_keytab_file]
          session_opts[:realm] = Chef::Config[:knife][:kerberos_realm] if Chef::Config[:knife][:kerberos_realm]
          session_opts[:service] = Chef::Config[:knife][:kerberos_service] if Chef::Config[:knife][:kerberos_service]
          session_opts[:ca_trust_path] = Chef::Config[:knife][:ca_trust_file] if Chef::Config[:knife][:ca_trust_file]
          session_opts[:operation_timeout] = 1800 # 30 min OperationTimeout for long bootstraps fix for KNIFE_WINDOWS-8

          ## If you have a \\ in your name you need to use NTLM domain authentication
          if session_opts[:user].split("\\").length.eql?(2)
            session_opts[:basic_auth_only] = false
          else
            session_opts[:basic_auth_only] = true
          end

          if config.keys.any? {|k| k.to_s =~ /kerberos/ }
            session_opts[:transport] = :kerberos
            session_opts[:basic_auth_only] = false
          else
            session_opts[:transport] = (Chef::Config[:knife][:winrm_transport] || config[:winrm_transport]).to_sym
            session_opts[:disable_sspi] = true
            if session_opts[:user] and
                (not session_opts[:password])
              session_opts[:password] = Chef::Config[:knife][:winrm_password] = config[:winrm_password] = get_password

            end
          end

          session.use(item, session_opts)

          @longest = item.length if item.length > @longest
        end
        session
      end

      def print_data(host, data, color = :cyan)
        if data =~ /\n/
          data.split(/\n/).each { |d| print_data(host, d, color) }
        else
          padding = @longest - host.length
          print ui.color(host, color)
          padding.downto(0) { print " " }
          puts data.chomp
        end
      end

      def winrm_command(command, subsession=nil)
        subsession ||= session
        subsession.relay_command(command)
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
            session.close
            break
          when /^on (.+?); (.+)$/
            raw_list = $1.split(" ")
            server_list = Array.new
            session.servers.each do |session_server|
              server_list << session_server if raw_list.include?(session_server.host)
            end
            command = $2
            winrm_command(command, session.on(*server_list))
          else
            winrm_command(command)
          end
        end
      end

      def check_for_errors!(exit_codes)

        exit_codes.each do |host, value|
          unless Chef::Config[:knife][:returns].include? value.to_i
            @exit_code = 1
            ui.error "Failed to execute command on #{host} return code #{value}"
          end
        end

      end

      def run
        STDOUT.sync = STDERR.sync = true

        begin
          @longest = 0

          configure_session

          case @name_args[1]
          when "interactive"
            interactive
          else
            winrm_command(@name_args[1..-1].join(" "))

            if config[:returns]
              check_for_errors! session.exit_codes
            end

            session.close
            @exit_code || 0
          end
        rescue WinRM::WinRMHTTPTransportError => e
          case e.message
          when /401/
            ui.error "Failed to authenticate to #{@name_args[0].split(" ")} as #{config[:winrm_user]}"
            ui.info "Response: #{e.message}"
          else
            raise e
          end
        end
      end

    end
  end
end

