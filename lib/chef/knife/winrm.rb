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
require 'chef/data_bag_item'

begin
  gem "em-winrm"
rescue LoadError
end

class Chef
  class Knife
    class Winrm < Knife

      attr_writer :password

      banner "knife winrm QUERY COMMAND (options)"

      option :attribute,
        :short => "-a ATTR",
        :long => "--attribute ATTR",
        :description => "The attribute to use for opening the connection - default is fqdn",
        :default => "fqdn" 

      option :manual,
        :short => "-m",
        :long => "--manual-list",
        :boolean => true,
        :description => "QUERY is a space separated list of servers",
        :default => false

      option :winrm_user,
        :short => "-x USERNAME",
        :long => "--winrm-user USERNAME",
        :description => "The WinRM username"

      option :winrm_password,
        :short => "-P PASSWORD",
        :long => "--winrm-password PASSWORD",
        :description => "The WinRM password"

      option :winrm_port,
        :short => "-p PORT",
        :long => "--winrm-port PORT",
        :description => "The WinRM port",
        :default => "80",
        :proc => Proc.new { |key| Chef::Config[:knife][:winrm_port] = key }

      option :winrm_transport,
        :short => "-t TRANSPORT",
        :long => "--winrm-transport TRANSPORT",
        :description => "The WinRM transport type: ssl, or plaintext",
        :default => 'plaintext',
        :proc => Proc.new { |transport| Chef::Config[:knife][:winrm_transport] = transport }

      option :kerberos_keytab_file,
        :short => "-i KEYTAB_FILE",
        :long => "--keytab-file KEYTAB_FILE",
        :description => "The Kerberos keytab file used for authentication",
        :proc => Proc.new { |keytab| Chef::Config[:knife][:kerberos_keytab_file] = keytab }

      option :kerberos_realm,
        :short => "-R KERBEROS_REALM",
        :long => "--kerberos-realm KERBEROS_REALM",
        :description => "The Kerberos realm used for authentication",
        :proc => Proc.new { |realm| Chef::Config[:knife][:kerberos_realm] = realm }

      option :kerberos_service,
        :short => "-S KERBEROS_SERVICE",
        :long => "--kerberos-service KERBEROS_SERVICE",
        :description => "The Kerberos service used for authentication",
        :proc => Proc.new { |service| Chef::Config[:knife][:kerberos_service] = service }

      option :keytab_file,
        :short => "-i KEYTAB_FILE",
        :long => "--keytab-file KEYTAB_FILE",
        :description => "The Kerberos keytab file used for authentication",
        :proc => Proc.new { |keytab| Chef::Config[:knife][:keytab_file] = keytab }

      option :ca_trust_file,
        :short => "-f CA_TRUST_FILE",
        :long => "--ca-trust-file CA_TRUST_FILE",
        :description => "The Certificate Authority (CA) trust file used for SSL transport",
        :proc => Proc.new { |trust| Chef::Config[:knife][:ca_trust_file] = trust }

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

      def h
        @highline ||= HighLine.new
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
                   i = format_for_display(item)[config[:attribute]]
                   r.push(i) unless i.nil?
                 end
                 r
               end
        (Chef::Log.fatal("No nodes returned from search!"); exit 10) if list.length == 0
        session_from_list(list)
      end

      def session_from_list(list)
        list.each do |item|
          Chef::Log.debug("Adding #{item}")

          session_opts = {}
          session_opts[:user] = config[:winrm_user] if config[:winrm_user]
          session_opts[:password] = config[:winrm_password] if config[:winrm_password]
          session_opts[:port] = config[:winrm_port]
          session_opts[:keytab] = config[:kerberos_keytab_file] if config[:kerberos_keytab_file]
          session_opts[:realm] = config[:kerberos_realm] if config[:kerberos_realm]
          session_opts[:service] = config[:kerberos_service] if config[:kerberos_service]
          session_opts[:ca_trust_path] = config[:ca_trust_file] if config[:ca_trust_file]
          
          if config.keys.any? {|k| k.to_s =~ /kerberos/ }
            session_opts[:transport] = :kerberos
          else
            session_opts[:transport] = config[:winrm_transport].to_sym
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
          print h.color(host, color)
          padding.downto(0) { print " " }
          puts data.chomp
        end
      end

      def winrm_command(command, subsession=nil)
        subsession ||= session
        subsession.relay_command(command)
      end

      def get_password
        @password ||= h.ask("Enter your password: ") { |q| q.echo = false }
      end

      # Present the prompt and read a single line from the console. It also
      # detects ^D and returns "exit" in that case. Adds the input to the
      # history, unless the input is empty. Loops repeatedly until a non-empty
      # line is input.
      def read_line
        loop do
          command = reader.readline("#{h.color('knife-winrm>', :bold)} ", true)

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
        puts "Connected to #{h.list(session.servers.collect { |s| h.color(s.host, :cyan) }, :inline, " and ")}"
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

      def run 
        @longest = 0
        load_late_dependencies

        configure_session

        case @name_args[1]
        when "interactive"
          interactive 
        else
          winrm_command(@name_args[1..-1].join(" "))
          session.close
        end
      end

      def load_late_dependencies
        require 'readline'
        %w[em-winrm highline].each do |dep|
          load_late_dependency dep
        end
      end

    end
  end
end

