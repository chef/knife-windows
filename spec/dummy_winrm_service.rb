module Dummy
  class WinRMTransport
    attr_reader :httpcli


    def initialize
      @httpcli = HTTPClient.new
    end
  end

  class WinRMService
    attr_reader :xfer
    attr_accessor :logger

    def initialize
      @xfer = WinRMTransport.new
    end

    def set_timeout(timeout); end
    def create_executor; end
  end
end
