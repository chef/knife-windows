#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2011-2016 Chef Software, Inc.
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

require 'chef/knife/core/bootstrap_context'
# Chef::Util::PathHelper in Chef 11 is a bit juvenile still
require 'knife-windows/path_helper'
# require 'chef/util/path_helper'
require 'chef/knife/core/windows_bootstrap_context'

class Chef
  class Knife
    module Core
      # Instances of BootstrapContext are the context objects (i.e., +self+) for
      # bootstrap templates. For backwards compatability, they +must+ set the
      # following instance variables:
      # * @config   - a hash of knife's config values
      # * @run_list - the run list for the node to boostrap
      #
      class WindowsBootstrapContext < BootstrapContext
        PathHelper = ::Knife::Windows::PathHelper

        attr_accessor :client_pem

        def initialize(config, run_list, chef_config, secret=nil)
          @config       = config
          @run_list     = run_list
          @chef_config  = chef_config
          @secret       = secret
          # Compatibility with Chef 12 and Chef 11 versions
          begin
            # Pass along the secret parameter for Chef 12
            super(config, run_list, chef_config, secret)
          rescue ArgumentError
            # The Chef 11 base class only has parameters for initialize
            super(config, run_list, chef_config)
          end
        end

        def validation_key
          if File.exist?(File.expand_path(@chef_config[:validation_key]))
            IO.read(File.expand_path(@chef_config[:validation_key]))
          else
            false
          end
        end

        def secret
          if @config[:secret].nil?
            nil
          else
            escape_and_echo(@config[:secret])
          end
        end

        def trusted_certs_script
          @trusted_certs_script ||= trusted_certs_content
        end

        def config_content
          client_rb = <<-CONFIG
chef_server_url  "#{@chef_config[:chef_server_url]}"
validation_client_name "#{@chef_config[:validation_client_name]}"
file_cache_path   "c:/chef/cache"
file_backup_path  "c:/chef/backup"
cache_options     ({:path => "c:/chef/cache/checksums", :skip_expires => true})
          CONFIG
          if @config[:chef_node_name]
            client_rb << %Q{node_name "#{@config[:chef_node_name]}"\n}
          else
            client_rb << "# Using default node name (fqdn)\n"
          end

          if @chef_config[:config_log_level]
            client_rb << %Q{log_level :#{@chef_config[:config_log_level]}\n}
          else
            client_rb << "log_level        :info\n"
          end

          client_rb << "log_location       #{get_log_location}"

          # We configure :verify_api_cert only when it's overridden on the CLI
          # or when specified in the knife config.
          if !@config[:node_verify_api_cert].nil? || knife_config.has_key?(:verify_api_cert)
            value = @config[:node_verify_api_cert].nil? ? knife_config[:verify_api_cert] : @config[:node_verify_api_cert]
            client_rb << %Q{verify_api_cert #{value}\n}
          end

          # We configure :ssl_verify_mode only when it's overridden on the CLI
          # or when specified in the knife config.
          if @config[:node_ssl_verify_mode] || knife_config.has_key?(:ssl_verify_mode)
            value = case @config[:node_ssl_verify_mode]
            when "peer"
              :verify_peer
            when "none"
              :verify_none
            when nil
              knife_config[:ssl_verify_mode]
            else
              nil
            end

            if value
              client_rb << %Q{ssl_verify_mode :#{value}\n}
            end
          end

          if @config[:ssl_verify_mode]
            client_rb << %Q{ssl_verify_mode :#{knife_config[:ssl_verify_mode]}\n}
          end

          if knife_config[:bootstrap_proxy]
            client_rb << "\n"
            client_rb << %Q{http_proxy        "#{knife_config[:bootstrap_proxy]}"\n}
            client_rb << %Q{https_proxy       "#{knife_config[:bootstrap_proxy]}"\n}
            client_rb << %Q{no_proxy          "#{knife_config[:bootstrap_no_proxy]}"\n} if knife_config[:bootstrap_no_proxy]
          end

          if knife_config[:bootstrap_no_proxy]
            client_rb << %Q{no_proxy       "#{knife_config[:bootstrap_no_proxy]}"\n}
          end

          if @config[:secret]
            client_rb << %Q{encrypted_data_bag_secret "c:/chef/encrypted_data_bag_secret"\n}
          end

          unless trusted_certs_script.empty?
            client_rb << %Q{trusted_certs_dir "c:/chef/trusted_certs"\n}
          end

          if Chef::Config[:fips]
            client_rb << <<-CONFIG
fips true
chef_version = ::Chef::VERSION.split(".")
unless chef_version[0].to_i > 12 || (chef_version[0].to_i == 12 && chef_version[1].to_i >= 8)
  raise "FIPS Mode requested but not supported by this client"
end
CONFIG
          end

          escape_and_echo(client_rb)
        end

        def get_log_location
          if @chef_config[:config_log_location].equal?(:win_evt)
            %Q{:#{@chef_config[:config_log_location]}\n}
          elsif @chef_config[:config_log_location].equal?(:syslog)
            raise "syslog is not supported for log_location on Windows OS\n"
          elsif (@chef_config[:config_log_location].equal?(STDOUT))
            "STDOUT\n"
          elsif (@chef_config[:config_log_location].equal?(STDERR))
            "STDERR\n"
          elsif @chef_config[:config_log_location].nil? || @chef_config[:config_log_location].empty?
            "STDOUT\n"
          elsif @chef_config[:config_log_location]
            %Q{"#{@chef_config[:config_log_location]}"\n}
          else
            "STDOUT\n"
          end
        end

        def chef_version_in_url
          installer_version_string = nil
          if @config[:bootstrap_version]
            installer_version_string = "&v=#{@config[:bootstrap_version]}"
          elsif @config[:prerelease]
            installer_version_string = "&prerelease=true"
          else
            chef_version_string = if knife_config[:bootstrap_version]
              knife_config[:bootstrap_version]
            else
              Chef::VERSION.split(".").first
            end

            installer_version_string = "&v=#{chef_version_string}"

            # If bootstrapping a pre-release version add the prerelease query string
            if chef_version_string.split(".").length > 3
              installer_version_string << "&prerelease=true"
            end
          end

          installer_version_string
        end

        def win_ps_write_filechunk
          win_ps_write_filechunk = <<-PS_WRITEFILECHUNK
$data=$args[0]
$filename=$args[1]
$bytes = @()
if (Test-Path $filename) { $bytes = [System.IO.File]::ReadAllBytes($filename) }
$bytes += $args[0]
[io.file]::WriteAllBytes($filename,$bytes)
PS_WRITEFILECHUNK
		  escape_and_echo(win_ps_write_filechunk)
		end

        def win_cmd_wait_for_file(filename_in_envvar)
          win_cmd_wait_for_file = <<-filename_in_envvar
:waitfor#{filename_in_envvar}
@if NOT EXIST "%#{filename_in_envvar}%" (
    @powershell.exe -command Start-Sleep 1
	@echo %#{filename_in_envvar}% does not exist yet.
    @goto waitfor#{filename_in_envvar}
) else (
    @echo Logfile %#{filename_in_envvar}% found.
)
filename_in_envvar
          win_cmd_wait_for_file
        end

        def win_cmd_tail(target_filename)
          cmd_tail_file = Gem.find_files(File.join('chef', 'knife', 'bootstrap', 'tail.cmd')).first
          cmd_tail_content = IO.read(cmd_tail_file)
          win_parse_file_content(cmd_tail_content, target_filename)
        end

        def bootstrap_context
          @bootstrap_context ||= Knife::Core::WindowsBootstrapContext.new(@config, @config[:run_list], Chef::Config)
        end

        def win_ps_bootstrap(target_filename)
          ps_bootstrap_file = Gem.find_files(File.join('chef', 'knife', 'bootstrap', 'bootstrap.ps1')).first
          ps_bootstrap_content = IO.read(ps_bootstrap_file)
          win_parse_file_content(ps_bootstrap_content, target_filename)
        end

        def win_schedtask_xml(target_filename)
          sched_xml_file = Gem.find_files(File.join('chef', 'knife', 'bootstrap', 'Chef_bootstrap.erb')).first
          sched_xml_file_content = IO.read(sched_xml_file).chomp
          win_parse_file_content(Erubis::Eruby.new(sched_xml_file_content).evaluate(bootstrap_context), target_filename)
        end

        def win_folder_cp(folder_src,folder_dest, folder_src_original = nil)
          win_folder_cp = ''
          Dir.foreach(folder_src) do |item|
            next if item == '.' or item == '..'
            folder_src_original = folder_src_original ? folder_src_original : folder_src
            if File.file?(File.join(folder_src,item))
              filename_target = File.join(folder_src,item).gsub(folder_src_original, folder_dest).gsub("/","\\")
              win_folder_cp << win_parse_file_content(IO.read(File.join(folder_src,item)).force_encoding('binary'), filename_target)
            else
              folder = File.join(folder_src,item).gsub(folder_src_original, folder_dest).gsub("/","\\")
              win_folder_cp << "mkdir #{folder}\n"
              win_folder_cp << win_folder_cp(File.join(folder_src,item), folder_dest, folder_src_original)
            end
          end
          win_folder_cp
        end

    def win_parse_file_content(content, target_filename)
		  byte_chunks = data_to_byte_chunks(content, 2000)
		  win_parse_file_content = ''
		  win_parse_file_content << "del \"#{target_filename}\" /Q 2> nul\n"
		  byte_chunks.each { |file_chunk|
			   if file_chunk.length > 0
   			  win_parse_file_content << write_file_chunk(file_chunk, target_filename)
   			end
		  }
		  win_parse_file_content
		end
		
		def write_file_chunk(byte_chunk, target_filename)
		  "@powershell.exe -command #{bootstrap_directory}\\writefile.ps1 #{byte_chunk} #{target_filename}\n"
		end
		
		def data_to_byte_chunks(data, max_chuck_size)
		  chunk = ''
		  chunk_buffer = ''
		  data_to_byte_chunks = []
		  data.split('').each { |char|
		    chunk_buffer << char.ord.to_s << ','
		    if (chunk_buffer.length) >= max_chuck_size
		      data_to_byte_chunks.push(chunk_buffer.chomp(','))
          chunk_buffer = ''
		    end
		  }
		  data_to_byte_chunks.push(chunk_buffer.chomp(','))
		  data_to_byte_chunks
		end


        def win_ps_exitcheck
          <<-ps_exitcheck
@powershell.exe -command Start-Sleep 1
@echo off
@if EXIST %CHEF_PS_EXITCODE% (
  setlocal disabledelayedexpansion
  for /f "tokens=1* delims=]" %%A in ('type "%CHEF_PS_EXITCODE%"^|find /v /n ""') do (
    set psexitcode=%%B
    setlocal enabledelayedexpansion
    if NOT !psexitcode!==0 (
      echo ERROR -- Powershell bootstrap script exit code was !psexitcode!
    )
    endlocal
  )
) else (
  echo %CHEF_PS_EXITCODE% not found. This should never happen
  exit 328
)
ps_exitcheck
        end

        def bootstrap_directory
          bootstrap_directory = "C:\\chef"
        end

        def local_download_path
          local_download_path = "%TEMP%\\chef-client-latest.msi"
        end

        def first_boot
          escape_and_echo(super.to_json)
        end

        # escape WIN BATCH special chars
        # and prefixes each line with an
        # echo
        def escape_and_echo(file_contents)
          file_contents.gsub(/^(.*)$/, 'echo.\1').gsub(/([(<|>)^])/, '^\1').gsub(/(!)/, '^^\1').gsub(/(%)/,'%\1')
        end

        private

        # Returns a string for copying the trusted certificates on the workstation to the system being bootstrapped
        # This string should contain both the commands necessary to both create the files, as well as their content
        def trusted_certs_content
          content = ""
          if @chef_config[:trusted_certs_dir]
            Dir.glob(File.join(PathHelper.escape_glob_dir(@chef_config[:trusted_certs_dir]), "*.{crt,pem}")).each do |cert|
              content << "> #{bootstrap_directory}/trusted_certs/#{File.basename(cert)} (\n" +
                         escape_and_echo(IO.read(File.expand_path(cert))) + "\n)\n"
            end
          end
          content
        end

      end
    end
  end
end
