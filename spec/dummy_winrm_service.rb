module Dummy
  class WinRMTransport
    attr_reader :httpcli

    def initialize
      @httpcli = HTTPClient.new
    end
  end

  class WinRMService
    attr_reader :xfer

    def initialize
      @xfer = WinRMTransport.new
    end

    def set_timeout(timeout); end
    def open_shell; end
    def run_command; end
    def get_command_output; end
    def cleanup_command; end
    def close_shell; end
  end
end
